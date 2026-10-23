import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/room.dart';
import 'theme/app_colors.dart';
import 'widgets/auto_slide_services.dart';
import 'widgets/app_network_image.dart';
import 'providers/rooms_provider.dart';
import 'navigation/room_navigation.dart';
import 'core/navigation/app_shell.dart';
import 'core/responsive/app_container.dart';
import 'core/responsive/breakpoints.dart';

const _experienceCream = AppColors.cream;
const _experienceCard = AppColors.surface;
const _experienceNavy = AppColors.navy;
const _experienceGold = AppColors.gold;
const _experienceLightGold = AppColors.gold;

class PropertyContent {
  const PropertyContent({
    required this.id,
    required this.name,
    required this.description,
    required this.contactPhone,
    required this.contactEmail,
    required this.address,
  });

  final String id;
  final String name;
  final String description;
  final String contactPhone;
  final String contactEmail;
  final String address;

  factory PropertyContent.fromRow(Map<String, dynamic> data) {
    return PropertyContent(
      id: _stringValue(data['id']),
      name: _stringValue(data['name']),
      description: _stringValue(data['description']),
      contactPhone: _stringValue(data['phone']),
      contactEmail: _stringValue(data['email']),
      address: _stringValue(data['address']),
    );
  }
}

class PropertyService {
  const PropertyService({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });

  final String id;
  final String name;
  final String description;
  final String iconName;

  factory PropertyService.fromRow(Map<String, dynamic> data) {
    return PropertyService(
      id: _stringValue(data['id']),
      name: _stringValue(data['name']),
      description: _stringValue(data['description']),
      iconName: _stringValue(data['image_url']),
    );
  }
}

class ServiceItem {
  const ServiceItem({
    required this.icon,
    required this.name,
    required this.description,
  });

  final IconData icon;
  final String name;
  final String description;

  factory ServiceItem.fromPropertyService(PropertyService service) {
    final normalized = service.name.toLowerCase();
    final icon = switch (normalized) {
      final name when name.contains('housekeep') =>
        Icons.cleaning_services_rounded,
      final name when name.contains('laundry') =>
        Icons.local_laundry_service_rounded,
      final name when name.contains('wifi') => Icons.wifi_rounded,
      final name when name.contains('room service') =>
        Icons.room_service_rounded,
      final name when name.contains('airport') || name.contains('pickup') =>
        Icons.local_taxi_rounded,
      final name when name.contains('restaurant') => Icons.restaurant_rounded,
      _ => Icons.star_rounded,
    };
    return ServiceItem(
      icon: icon,
      name: service.name,
      description: service.description,
    );
  }
}

class AboutStats {
  const AboutStats({required this.rooms, required this.averageRating});

  final int rooms;
  final double? averageRating;
}

class PropertyRoom {
  const PropertyRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.pricePerNight,
    required this.capacity,
    required this.amenities,
    required this.imageUrls,
    required this.availability,
  });

  final String id;
  final String name;
  final String type;
  final String description;
  final num pricePerNight;
  final int capacity;
  final List<String> amenities;
  final List<String> imageUrls;
  final String availability;

  factory PropertyRoom.fromRow(Map<String, dynamic> data) {
    final capacity = data['capacity'];
    final price = data['price_per_night'];
    return PropertyRoom(
      id: _stringValue(data['id']),
      name: _stringValue(data['room_name']),
      type: _stringValue(data['room_type']),
      description: _stringValue(data['description']),
      pricePerNight: num.tryParse(price.toString()) ?? 0,
      capacity: num.tryParse(capacity.toString())?.toInt() ?? 0,
      amenities: _stringList(data['amenities']),
      imageUrls: _stringList(
        data['image_urls'] ?? data['images'] ?? data['image_url'],
      ),
      availability: _stringValue(data['status']),
    );
  }
}

class PropertyContentRepository {
  const PropertyContentRepository({this.supabaseClient});

  final SupabaseClient? supabaseClient;
  SupabaseClient get _supabase => supabaseClient ?? Supabase.instance.client;

  Future<PropertyContent?> getActiveProperty() async {
    try {
      final result = await _supabase
          .from('properties')
          .select('id,name,description,address,phone,email')
          .eq('is_published', true)
          .order('created_at')
          .limit(1)
          .maybeSingle();
      if (kDebugMode) {
        debugPrint(
          '[PropertyContentRepository] Active-property query returned '
          '${result == null ? 0 : 1} row(s).',
        );
      }
      if (result == null) return null;
      if (kDebugMode) {
        debugPrint(
          '[PropertyContentRepository] Selected published property '
          'row ${result['id']}.',
        );
      }
      return PropertyContent.fromRow(result);
    } catch (error, stackTrace) {
      _logPropertyDataFailure('Load active property', error, stackTrace);
      rethrow;
    }
  }

  Future<List<PropertyService>> getServices() async {
    try {
      final rows = await _supabase
          .from('services')
          .select('id,name,description,image_url')
          .eq('is_active', true)
          .order('created_at');
      return rows
          .map(PropertyService.fromRow)
          .where((service) => service.name.isNotEmpty)
          .toList();
    } catch (error, stackTrace) {
      _logPropertyDataFailure('Load active services', error, stackTrace);
      rethrow;
    }
  }

  Future<List<ServiceItem>> getServiceItems() async => (await getServices())
      .take(8)
      .map(ServiceItem.fromPropertyService)
      .toList();

  Future<AboutStats> getAboutStats() async {
    try {
      final rows = await _supabase
          .from('rooms')
          .select('id,rating')
          .eq('is_published', true);
      final ratings = rows
          .map((row) => num.tryParse(row['rating']?.toString() ?? ''))
          .whereType<num>()
          .map((rating) => rating.toDouble())
          .toList();
      final average = ratings.isEmpty
          ? null
          : ratings.reduce((sum, rating) => sum + rating) / ratings.length;
      return AboutStats(rooms: rows.length, averageRating: average);
    } catch (error, stackTrace) {
      _logPropertyDataFailure('Load About stats', error, stackTrace);
      rethrow;
    }
  }

  Future<List<PropertyRoom>> getRooms(String propertyId) async {
    try {
      final rows = await _supabase
          .from('rooms')
          .select(
            'id, property_id, room_name, room_type, description, '
            'price_per_night, capacity, amenities, image_urls, status, '
            'is_published, created_at',
          )
          .eq('property_id', propertyId)
          .eq('is_published', true)
          .order('created_at');
      return rows
          .map(PropertyRoom.fromRow)
          .where((room) => room.name.isNotEmpty)
          .toList();
    } catch (error, stackTrace) {
      _logPropertyDataFailure(
        'Load published rooms for property $propertyId',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> createContactMessage({
    required String name,
    required String email,
    String? phone,
    required String message,
  }) async {
    try {
      await _supabase.from('contact_messages').insert({
        'name': name.trim(),
        'email': email.trim(),
        'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        'message': message.trim(),
      });
    } catch (error, stackTrace) {
      _logPropertyDataFailure('Save contact message', error, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to view your bookings.');
    }
    try {
      final rows = await _supabase
          .from('bookings')
          .select('*, rooms(*)')
          .eq('firebase_uid', user.uid)
          .order('created_at', ascending: false);
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (error, stackTrace) {
      _logPropertyDataFailure('Load current user bookings', error, stackTrace);
      rethrow;
    }
  }
}

void _logPropertyDataFailure(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  if (kDebugMode) {
    debugPrint(
      '[PropertyContentRepository] $operation failed: $error\n$stackTrace',
    );
  }
}

String _stringValue(Object? value) => value is String ? value.trim() : '';

List<String> _stringList(Object? value) => value is String
    ? value.trim().isEmpty
          ? const []
          : [value.trim()]
    : value is Iterable
    ? value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];

class PropertyAboutScreen extends StatefulWidget {
  const PropertyAboutScreen({
    this.repository = const PropertyContentRepository(),
    super.key,
  });

  final PropertyContentRepository repository;

  @override
  State<PropertyAboutScreen> createState() => _PropertyAboutScreenState();
}

class _PropertyAboutScreenState extends State<PropertyAboutScreen> {
  late Future<PropertyContent?> _property;

  @override
  void initState() {
    super.initState();
    _property = widget.repository.getActiveProperty();
  }

  @override
  Widget build(BuildContext context) => _PropertyPage(
    title: 'About Atithi',
    activeRoute: '/about',
    child: FutureBuilder<PropertyContent?>(
      future: _property,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PageState(
            message: 'We could not load property information.',
            diagnostic: _debugDataError(snapshot.error),
            onRetry: () => setState(
              () => _property = widget.repository.getActiveProperty(),
            ),
            isError: true,
          );
        }
        if (!snapshot.hasData) return const _PageLoading();
        final property = snapshot.data;
        if (property == null) {
          return const _PageState(
            message: 'Property information is not available yet.',
          );
        }
        return _AboutContent(property: property, repository: widget.repository);
      },
    ),
  );
}

class _AboutContent extends StatefulWidget {
  const _AboutContent({required this.property, required this.repository});

  final PropertyContent property;
  final PropertyContentRepository repository;

  @override
  State<_AboutContent> createState() => _AboutContentState();
}

class _AboutContentState extends State<_AboutContent>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _shimmerController;
  late Future<AboutStats> _statsFuture;
  bool? _motionDisabled;

  @override
  void initState() {
    super.initState();
    _statsFuture = widget.repository.getAboutStats();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.of(context).disableAnimations;
    if (_motionDisabled == disabled) return;
    _motionDisabled = disabled;
    if (disabled) {
      _entranceController.stop();
      _entranceController.value = 1;
      _shimmerController.stop();
    } else {
      _entranceController.forward();
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Animation<double> _entranceFor(int index, Curve curve) {
    final start = (index * .085).clamp(0.0, .82);
    final end = (start + .3).clamp(.01, 1.0);
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: curve),
    );
  }

  Widget _enter(int index, Widget child) {
    final interval = _entranceFor(index, Curves.easeOutCubic);
    return FadeTransition(
      opacity: interval,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .12),
          end: Offset.zero,
        ).animate(interval),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = _motionDisabled ?? false;
    final reasons = _WhyAtithi.reasons;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final introduction = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _enter(
                  1,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          final progress = reducedMotion
                              ? 0.5
                              : _shimmerController.value;
                          final shift = -1.6 + progress * 3.2;
                          return ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment(shift, 0),
                              end: Alignment(shift + 1.1, 0),
                              colors: const [
                                _experienceNavy,
                                _experienceGold,
                                _experienceNavy,
                              ],
                              stops: const [0.35, 0.5, 0.65],
                            ).createShader(bounds),
                            child: child,
                          );
                        },
                        child: Text(
                          'Atithi',
                          style: GoogleFonts.playfairDisplay(
                            color: _experienceNavy,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 66),
                        duration: reducedMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 850),
                        curve: Curves.easeOutCubic,
                        builder: (context, width, _) => Container(
                          width: width,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _experienceGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _enter(
                  2,
                  Text(
                    widget.property.description.isEmpty
                        ? 'Property introduction is not available yet.'
                        : widget.property.description,
                    style: GoogleFonts.dmSans(
                      color: AppColors.secondaryText,
                      height: 1.65,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _enter(0, const _AboutHero())),
                  const SizedBox(width: 28),
                  Expanded(child: introduction),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _enter(0, const _AboutHero()),
                const SizedBox(height: 22),
                introduction,
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        _enter(3, _AboutStatsRow(statsFuture: _statsFuture)),
        const SizedBox(height: 24),
        _enter(
          4,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AboutSectionHeading('Our Services'),
              const SizedBox(height: 10),
              ServicesOrbit(
                loadItems: widget.repository.getServiceItems,
                reducedMotion: reducedMotion,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _enter(5, const _AboutSectionHeading('Why Choose Atithi?')),
        const SizedBox(height: 12),
        for (var index = 0; index < reasons.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _enter(
              6 + index,
              _WhyAtithiTile(
                reason: reasons[index],
                iconAnimation: _entranceFor(6 + index, Curves.elasticOut),
              ),
            ),
          ),
        const SizedBox(height: 12),
        _enter(
          10,
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_experienceNavy, Color(0xFF244C6C)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _experienceNavy.withValues(alpha: .2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => GoRouter.of(context).go('/rooms'),
                  child: Center(
                    child: Text(
                      'Book Your Stay',
                      style: GoogleFonts.dmSans(
                        color: _experienceCream,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutHero extends StatefulWidget {
  const _AboutHero();

  @override
  State<_AboutHero> createState() => _AboutHeroState();
}

class _AboutHeroState extends State<_AboutHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _motionDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.of(context).disableAnimations;
    if (_motionDisabled == disabled) return;
    _motionDisabled = disabled;
    if (disabled) {
      _controller.stop();
      _controller.value = .5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final progress = _controller.value;
      final floatY = _motionDisabled == true
          ? 0.0
          : math.sin(progress * math.pi * 2) * 8;
      return ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: 240,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.lerp(
                      Alignment.topLeft,
                      Alignment.bottomLeft,
                      progress,
                    )!,
                    end: Alignment.lerp(
                      Alignment.bottomRight,
                      Alignment.topRight,
                      progress,
                    )!,
                    colors: const [
                      Color(0xFF0B2036),
                      _experienceNavy,
                      Color(0xFF244B68),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                painter: _HeroAtmospherePainter(progress),
                child: const SizedBox.expand(),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(0, floatY),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _experienceCream.withValues(alpha: .08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _experienceLightGold.withValues(alpha: .65),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _experienceGold.withValues(alpha: .16),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: _experienceLightGold,
                      size: 42,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 18,
                child: Text(
                  'A refined stay, warmly remembered',
                  style: GoogleFonts.dmSans(
                    color: _experienceCream.withValues(alpha: .88),
                    fontSize: 12,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HeroAtmospherePainter extends CustomPainter {
  const _HeroAtmospherePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .52);
    for (var ring = 0; ring < 3; ring++) {
      final phase = (progress + ring / 3) % 1;
      final radius = 30 + phase * 142;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _experienceLightGold.withValues(alpha: (1 - phase) * .34);
      canvas.drawCircle(center, radius, paint);
    }
    const dots = <(double, double, double)>[
      (.14, .24, .2),
      (.82, .22, 1.4),
      (.23, .72, 2.1),
      (.76, .7, 3.4),
      (.42, .14, 4.3),
      (.91, .48, 5.5),
      (.08, .52, .9),
    ];
    for (final (x, y, phase) in dots) {
      final twinkle =
          .35 + .65 * ((math.sin(progress * math.pi * 2 + phase) + 1) / 2);
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        1.2 + twinkle * 1.2,
        Paint()..color = _experienceLightGold.withValues(alpha: twinkle * .8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AboutStatsRow extends StatelessWidget {
  const _AboutStatsRow({required this.statsFuture});
  final Future<AboutStats> statsFuture;

  @override
  Widget build(BuildContext context) => FutureBuilder<AboutStats>(
    future: statsFuture,
    builder: (context, snapshot) {
      final stats = snapshot.data;
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 16) / 3;
          return Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  label: 'Rooms',
                  value: stats?.rooms.toDouble() ?? 0,
                  suffix: '+',
                  displayUnavailable: snapshot.hasError || stats == null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: cardWidth,
                child: const _StatCard(
                  label: 'Support',
                  value: 24,
                  suffix: '/7',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  label: 'Rating',
                  value: stats?.averageRating ?? 0,
                  suffix: '★',
                  decimals: 1,
                  displayUnavailable:
                      snapshot.hasError || stats?.averageRating == null,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
    this.decimals = 0,
    this.displayUnavailable = false,
  });

  final String label;
  final double value;
  final String suffix;
  final int decimals;
  final bool displayUnavailable;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
    decoration: BoxDecoration(
      color: _experienceCard,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _experienceLightGold.withValues(alpha: .55)),
    ),
    child: Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, count, _) => Text(
            displayUnavailable
                ? '—'
                : '${count.toStringAsFixed(decimals)}$suffix',
            maxLines: 1,
            style: GoogleFonts.playfairDisplay(
              color: _experienceNavy,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            color: AppColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _AboutSectionHeading extends StatelessWidget {
  const _AboutSectionHeading(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.playfairDisplay(
      color: _experienceNavy,
      fontSize: 23,
      fontWeight: FontWeight.w700,
    ),
  );
}

class ServicesOrbit extends StatefulWidget {
  const ServicesOrbit({
    required this.loadItems,
    required this.reducedMotion,
    super.key,
  });

  final Future<List<ServiceItem>> Function() loadItems;
  final bool reducedMotion;

  @override
  State<ServicesOrbit> createState() => _ServicesOrbitState();
}

class _ServicesOrbitState extends State<ServicesOrbit>
    with SingleTickerProviderStateMixin {
  late Future<List<ServiceItem>> _itemsFuture;
  late final AnimationController _rotationController;
  Timer? _activeTimer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.loadItems();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    );
    if (!widget.reducedMotion) _rotationController.repeat();
  }

  @override
  void didUpdateWidget(covariant ServicesOrbit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadItems != widget.loadItems) {
      _itemsFuture = widget.loadItems();
      _activeIndex = 0;
    }
    if (oldWidget.reducedMotion != widget.reducedMotion) {
      if (widget.reducedMotion) {
        _rotationController.stop();
        _rotationController.value = 0;
        _activeTimer?.cancel();
      } else {
        _rotationController.repeat();
        _startActiveTimer();
      }
    }
  }

  void _startActiveTimer([int itemCount = 0]) {
    _activeTimer?.cancel();
    if (widget.reducedMotion || itemCount < 2) return;
    _activeTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() => _activeIndex = (_activeIndex + 1) % itemCount);
    });
  }

  void _retry() {
    setState(() {
      _activeIndex = 0;
      _itemsFuture = widget.loadItems();
    });
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ServiceItem>>(
    future: _itemsFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _InlineDataState(
          text: 'Services could not be loaded. Please try again.',
          diagnostic: _debugDataError(snapshot.error),
          onRetry: _retry,
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(height: 320, child: _InlineLoading());
      }
      final items = snapshot.data ?? const <ServiceItem>[];
      if (items.isEmpty) {
        return const _InlineDataState(
          text: 'Services will appear here when available.',
        );
      }
      if (!widget.reducedMotion && _activeTimer == null && items.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeTimer == null) {
            _startActiveTimer(items.length);
          }
        });
      }
      final active = _activeIndex % items.length;
      return SizedBox(
        height: 330,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, 360.0);
            final center = Offset(width / 2, 165);
            final radius = math.min(width / 2 - 24, 130.0);
            return Center(
              child: SizedBox(
                width: width,
                height: 330,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _OrbitRingPainter(_experienceGold),
                        ),
                      ),
                      for (var index = 0; index < items.length; index++)
                        _orbitNode(
                          item: items[index],
                          index: index,
                          count: items.length,
                          active: index == active,
                          angleProgress: widget.reducedMotion
                              ? 0.0
                              : _rotationController.value * math.pi * 2,
                          center: center,
                          radius: radius,
                        ),
                      Center(
                        child: Container(
                          width: 176,
                          height: 176,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _experienceCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _experienceLightGold.withValues(alpha: .9),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _experienceNavy.withValues(alpha: .12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: widget.reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 350),
                            child: Column(
                              key: ValueKey(items[active].name),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  items[active].icon,
                                  color: _experienceGold,
                                  size: 31,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  items[active].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    color: _experienceNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  items[active].description.isEmpty
                                      ? 'Thoughtful service for a comfortable stay.'
                                      : items[active].description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.secondaryText,
                                    fontSize: 10,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );

  Widget _orbitNode({
    required ServiceItem item,
    required int index,
    required int count,
    required bool active,
    required double angleProgress,
    required Offset center,
    required double radius,
  }) {
    final angle = -math.pi / 2 + angleProgress + index * math.pi * 2 / count;
    final offset = Offset(
      center.dx + math.cos(angle) * radius - 24,
      center.dy + math.sin(angle) * radius - 24,
    );
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Semantics(
        button: true,
        selected: active,
        label: item.name,
        child: GestureDetector(
          onTap: () {
            setState(() => _activeIndex = index);
            _startActiveTimer(count);
          },
          child: AnimatedScale(
            scale: active ? 1.18 : 1,
            duration: widget.reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: widget.reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active ? _experienceGold : _experienceCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? _experienceLightGold : _experienceGold,
                  width: active ? 2 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _experienceGold.withValues(alpha: .4),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ]
                    : const [],
              ),
              child: Icon(
                item.icon,
                color: active ? Colors.white : _experienceNavy,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2 - 24, 130.0);
    final paint = Paint()
      ..color = color.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const dashCount = 64;
    final circumference = math.pi * 2 * radius;
    final dashLength = circumference / dashCount * .48;
    for (var index = 0; index < dashCount; index++) {
      final start = index * math.pi * 2 / dashCount;
      final end = start + dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WhyAtithiTile extends StatelessWidget {
  const _WhyAtithiTile({required this.reason, required this.iconAnimation});
  final (String, IconData) reason;
  final Animation<double> iconAnimation;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: BoxDecoration(
      color: _experienceCard,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _experienceLightGold.withValues(alpha: .65)),
    ),
    child: Row(
      children: [
        ScaleTransition(
          scale: iconAnimation,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: _experienceLightGold.withValues(alpha: .34),
            child: Icon(reason.$2, color: _experienceGold, size: 21),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            reason.$1,
            style: GoogleFonts.dmSans(
              color: _experienceNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class PropertyServicesScreen extends StatefulWidget {
  const PropertyServicesScreen({
    this.repository = const PropertyContentRepository(),
    super.key,
  });

  final PropertyContentRepository repository;

  @override
  State<PropertyServicesScreen> createState() => _PropertyServicesScreenState();
}

class _PropertyServicesScreenState extends State<PropertyServicesScreen> {
  late Future<PropertyContent?> _property;
  Future<List<PropertyService>>? _services;
  String? _servicesPropertyId;
  bool _servicesLoaded = false;

  @override
  void initState() {
    super.initState();
    _property = widget.repository.getActiveProperty();
  }

  @override
  Widget build(BuildContext context) => _PropertyPage(
    title: 'Our Services',
    activeRoute: '/services',
    child: FutureBuilder<PropertyContent?>(
      future: _property,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PageState(
            message: 'We could not load the available services.',
            diagnostic: _debugDataError(snapshot.error),
            isError: true,
            onRetry: _retry,
          );
        }
        if (!snapshot.hasData) {
          return const _PageLoading();
        }
        final property = snapshot.data;
        if (!_servicesLoaded || _servicesPropertyId != property?.id) {
          _servicesPropertyId = property?.id;
          _servicesLoaded = true;
          _services = widget.repository.getServices();
        }
        return FutureBuilder<List<PropertyService>>(
          future: _services,
          builder: (context, servicesSnapshot) {
            if (servicesSnapshot.hasError) {
              return _PageState(
                message: 'We could not load the available services.',
                diagnostic: _debugDataError(servicesSnapshot.error),
                isError: true,
                onRetry: _retry,
              );
            }
            if (!servicesSnapshot.hasData) {
              return const _PageLoading();
            }
            final services = servicesSnapshot.data!;
            if (services.isEmpty) {
              return const _PageState(
                message: 'No active services have been published yet.',
              );
            }
            final columns = context.screenWidth >= 1024
                ? 4
                : context.screenWidth >= 600
                ? 3
                : 2;
            return RefreshIndicator(
              onRefresh: () => _refreshServices(property?.id),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    sliver: SliverList.list(
                      children: [
                        if (property != null) ...[
                          const Text(
                            'Atithi',
                            style: TextStyle(
                              color: _experienceNavy,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 4,
                        childAspectRatio: columns == 2 ? 1.65 : 1.2,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _AnimatedSection(
                          delay: Duration(milliseconds: (i * 50).clamp(0, 400)),
                          child: _ServiceCard(service: services[i]),
                        ),
                        childCount: services.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );

  void _retry() {
    setState(() {
      _property = widget.repository.getActiveProperty();
      _services = null;
      _servicesPropertyId = null;
      _servicesLoaded = false;
    });
  }

  Future<void> _refreshServices(String? propertyId) async {
    final future = widget.repository.getServices();
    setState(() {
      _servicesPropertyId = propertyId;
      _services = future;
      _servicesLoaded = true;
    });
    await future;
  }
}

class PropertyContactScreen extends StatefulWidget {
  const PropertyContactScreen({
    this.repository = const PropertyContentRepository(),
    super.key,
  });

  final PropertyContentRepository repository;

  @override
  State<PropertyContactScreen> createState() => _PropertyContactScreenState();
}

class _PropertyContactScreenState extends State<PropertyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  late Future<PropertyContent?> _property;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _property = widget.repository.getActiveProperty();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.repository.createContactMessage(
        name: _name.text,
        email: _email.text,
        message: '${_subject.text.trim()}\n${_message.text.trim()}'.trim(),
      );
      if (!mounted) return;
      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your message was sent successfully.')),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Contact message submission failed: $error\n$stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not send your message. Please try again later.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PropertyPage(
    title: 'Contact Us',
    activeRoute: '/contact',
    child: FutureBuilder<PropertyContent?>(
      future: _property,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PageState(
            message: 'We could not load contact information.',
            diagnostic: _debugDataError(snapshot.error),
            isError: true,
            onRetry: () => setState(
              () => _property = widget.repository.getActiveProperty(),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const _PageLoading();
        }
        final property = snapshot.data;
        if (property == null) {
          return const _PageState(
            message: 'Contact information is not available yet.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _PropertyImage(url: null, height: 180),
            const SizedBox(height: 20),
            if (property.contactPhone.isEmpty &&
                property.contactEmail.isEmpty &&
                property.address.isEmpty)
              const _InfoSection(
                title: 'Contact information not available yet',
                body:
                    'Please check back later for the property contact details.',
              ),
            if (property.contactPhone.isNotEmpty)
              _ContactDetail(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: property.contactPhone,
                onTap: () => _launchContact(
                  context,
                  Uri(scheme: 'tel', path: property.contactPhone),
                ),
              ),
            if (property.contactEmail.isNotEmpty)
              _ContactDetail(
                icon: Icons.email_outlined,
                title: 'Email',
                value: property.contactEmail,
                onTap: () => _launchContact(
                  context,
                  Uri(scheme: 'mailto', path: property.contactEmail),
                ),
              ),
            if (property.address.isNotEmpty)
              _ContactDetail(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: property.address,
              ),
            const SizedBox(height: 18),
            const _SectionTitle('Send Us a Message'),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _ContactInput(
                    controller: _name,
                    label: 'Name',
                    maxLength: 120,
                    validator: (value) =>
                        _requiredField(value, label: 'name', maxLength: 120),
                  ),
                  _ContactInput(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 254,
                    validator: (value) {
                      final error = _validateEmail(value);
                      if (error != null) return error;
                      return value!.trim().length > 254
                          ? 'Email address is too long.'
                          : null;
                    },
                  ),
                  _ContactInput(
                    controller: _subject,
                    label: 'Subject',
                    maxLength: 160,
                    validator: (value) =>
                        _requiredField(value, label: 'subject', maxLength: 160),
                  ),
                  _ContactInput(
                    controller: _message,
                    label: 'Message',
                    maxLines: 4,
                    maxLength: 5000,
                    validator: (value) => _requiredField(
                      value,
                      label: 'message',
                      maxLength: 5000,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _experienceNavy,
                        foregroundColor: _experienceCream,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _experienceCream,
                              ),
                            )
                          : const Text('Submit Message'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class PropertyRoomsScreen extends StatefulWidget {
  const PropertyRoomsScreen({
    this.repository = const PropertyContentRepository(),
    this.selection,
    super.key,
  });

  final PropertyContentRepository repository;
  final RoomSearchSelection? selection;

  @override
  State<PropertyRoomsScreen> createState() => _PropertyRoomsScreenState();
}

class _PropertyRoomsScreenState extends State<PropertyRoomsScreen> {
  late Future<PropertyContent?> _property;
  Future<List<PropertyRoom>>? _rooms;
  String? _roomsPropertyId;

  @override
  void initState() {
    super.initState();
    _property = widget.repository.getActiveProperty();
  }

  @override
  Widget build(BuildContext context) => _PropertyPage(
    title: 'Our Rooms',
    child: FutureBuilder<PropertyContent?>(
      future: _property,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PageState(
            message: 'We could not load the room information.',
            diagnostic: _debugDataError(snapshot.error),
            isError: true,
            onRetry: _retry,
          );
        }
        if (!snapshot.hasData) {
          return const _PageLoading();
        }
        final property = snapshot.data;
        if (property == null) {
          return const _PageState(message: 'Rooms are not available yet.');
        }
        if (_roomsPropertyId != property.id || _rooms == null) {
          _roomsPropertyId = property.id;
          _rooms = widget.repository.getRooms(property.id);
        }
        return FutureBuilder<List<PropertyRoom>>(
          future: _rooms,
          builder: (context, roomsSnapshot) {
            if (roomsSnapshot.hasError) {
              return _PageState(
                message: 'We could not load the room information.',
                diagnostic: _debugDataError(roomsSnapshot.error),
                isError: true,
                onRetry: _retry,
              );
            }
            if (!roomsSnapshot.hasData) {
              return const _PageLoading();
            }
            final rooms = roomsSnapshot.data!;
            if (rooms.isEmpty) {
              return const _PageState(
                message: 'No rooms have been published for this property yet.',
              );
            }
            final dates = widget.selection == null
                ? ''
                : '\n${MaterialLocalizations.of(context).formatMediumDate(widget.selection!.checkIn)} – ${MaterialLocalizations.of(context).formatMediumDate(widget.selection!.checkOut)} · ${widget.selection!.adults} adults · ${widget.selection!.children} children';
            return RefreshIndicator(
              onRefresh: () => _refreshRooms(property.id),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  if (dates.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        dates.trim(),
                        style: const TextStyle(
                          color: _experienceNavy,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  for (final room in rooms)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RoomCard(
                        room: Room(
                          id: room.id,
                          roomName: room.name,
                          roomType: room.type,
                          description: room.description,
                          pricePerNight: room.pricePerNight.toDouble(),
                          capacity: room.capacity,
                          amenities: room.amenities,
                          imageUrls: room.imageUrls,
                          status: room.availability,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );

  void _retry() {
    setState(() {
      _property = widget.repository.getActiveProperty();
      _rooms = null;
      _roomsPropertyId = null;
    });
  }

  Future<void> _refreshRooms(String propertyId) async {
    final future = widget.repository.getRooms(propertyId);
    setState(() {
      _roomsPropertyId = propertyId;
      _rooms = future;
    });
    await future;
  }
}

class RoomSearchSelection {
  const RoomSearchSelection({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
}

class PropertyRoomDetailsScreen extends StatelessWidget {
  const PropertyRoomDetailsScreen({required this.room, super.key});
  final PropertyRoom room;

  @override
  Widget build(BuildContext context) => _PropertyPage(
    title: room.name,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        _RoomImageCarousel(imageUrls: room.imageUrls, height: 270),
        const SizedBox(height: 20),
        Text(
          room.name,
          style: const TextStyle(
            color: _experienceNavy,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (room.type.isNotEmpty)
          Text(
            room.type,
            style: const TextStyle(
              color: _experienceGold,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          room.description.isEmpty
              ? 'A comfortable room for your stay.'
              : room.description,
          style: const TextStyle(color: AppColors.secondaryText, height: 1.55),
        ),
        const SizedBox(height: 14),
        Text(
          '₹${room.pricePerNight} / night · Up to ${room.capacity} guests',
          style: const TextStyle(
            color: _experienceNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Availability: ${room.availability.isEmpty ? 'Not specified' : room.availability}',
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        if (room.amenities.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Amenities'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amenity in room.amenities)
                Chip(
                  label: Text(amenity),
                  backgroundColor: _experienceCard,
                  side: const BorderSide(color: _experienceLightGold),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _showBookingUnavailable(context),
          style: FilledButton.styleFrom(
            backgroundColor: _experienceNavy,
            foregroundColor: _experienceCream,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text('Book Now'),
        ),
      ],
    ),
  );
}

class PropertyBookingsScreen extends StatefulWidget {
  const PropertyBookingsScreen({
    this.repository = const PropertyContentRepository(),
    super.key,
  });

  final PropertyContentRepository repository;

  @override
  State<PropertyBookingsScreen> createState() => _PropertyBookingsScreenState();
}

class _PropertyBookingsScreenState extends State<PropertyBookingsScreen> {
  late Future<List<Map<String, dynamic>>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = widget.repository.getMyBookings();
  }

  @override
  Widget build(BuildContext context) => _PropertyPage(
    title: 'My Bookings',
    activeRoute: '/bookings',
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PageState(
            message: 'We could not load your bookings.',
            diagnostic: _debugDataError(snapshot.error),
            isError: true,
            onRetry: () =>
                setState(() => _bookings = widget.repository.getMyBookings()),
          );
        }
        if (!snapshot.hasData) return const _BookingsLoading();
        final bookings = snapshot.data!;
        if (bookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.luggage_outlined,
                    color: AppColors.darkGold,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No bookings yet',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Find your next comfortable stay with Atithi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.greyText),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => context.go('/rooms'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.cream,
                    ),
                    child: const Text('Find your stay'),
                  ),
                ],
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1024;
            return RefreshIndicator(
              onRefresh: () async {
                final future = widget.repository.getMyBookings();
                setState(() => _bookings = future);
                await future;
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1136),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: desktop ? 2 : 1,
                      mainAxisExtent: desktop ? 196 : 186,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final roomData = booking['rooms'];
                      final roomRow = roomData is Map
                          ? Map<String, dynamic>.from(roomData)
                          : const <String, dynamic>{};
                      final room =
                          _bookingValue(roomRow, 'room_name') ??
                          _bookingValue(roomRow, 'room_number') ??
                          _bookingValue(booking, 'room_id');
                      final roomImages = Room.fromJson(roomRow).imageUrls;
                      final imageUrl = roomImages.isEmpty
                          ? null
                          : roomImages.first;
                      final rawStatus = _bookingValue(
                        booking,
                        'booking_status',
                      );
                      final status = rawStatus?.toLowerCase() == 'pending'
                          ? 'Pending'
                          : rawStatus;
                      final checkIn = _bookingValue(booking, 'check_in');
                      final checkOut = _bookingValue(booking, 'check_out');
                      final total = _bookingValue(booking, 'total_amount');
                      final statusColor = status?.toLowerCase() == 'confirmed'
                          ? AppColors.darkGold
                          : status?.toLowerCase() == 'cancelled'
                          ? AppColors.greyText
                          : AppColors.navy;
                      return Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: _experienceCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _experienceLightGold.withValues(alpha: .65),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: SizedBox(
                                width: 90,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: AppNetworkImage(url: imageUrl),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          room ?? 'Reservation',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (status != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.cream,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (checkIn != null || checkOut != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Stay: ${checkIn ?? '—'} – ${checkOut ?? '—'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.greyText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (total != null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      'Total: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(num.tryParse(total) ?? 0)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _BookingsLoading extends StatelessWidget {
  const _BookingsLoading();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(20),
    itemCount: 4,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) => Shimmer.fromColors(
      baseColor: AppColors.gold.withValues(alpha: .16),
      highlightColor: AppColors.cream,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 16,
                    child: ColoredBox(color: AppColors.cream),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 130,
                    height: 12,
                    child: ColoredBox(color: AppColors.cream),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String? _bookingValue(Map<String, dynamic> booking, String key) {
  final value = booking[key];
  if (value != null && value.toString().trim().isNotEmpty) {
    return value.toString().trim();
  }
  return null;
}

class PropertyRoomsPreview extends ConsumerWidget {
  const PropertyRoomsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    return roomsAsync.when(
      loading: () => const _InlineLoading(),
      error: (error, stack) => _InlineDataState(
        text: 'Room information could not be loaded. Please try again.',
        diagnostic: _debugDataError(error),
        onRetry: () => ref.invalidate(roomsProvider),
      ),
      data: (rooms) {
        if (rooms.isEmpty) {
          return const _InlineDataState(text: 'No rooms are available yet.');
        }
        return _ResponsiveHomeRooms(rooms: rooms.take(5).toList());
      },
    );
  }
}

class _ResponsiveHomeRooms extends StatefulWidget {
  const _ResponsiveHomeRooms({required this.rooms});
  final List<Room> rooms;

  @override
  State<_ResponsiveHomeRooms> createState() => _ResponsiveHomeRoomsState();
}

class _ResponsiveHomeRoomsState extends State<_ResponsiveHomeRooms> {
  final PageController _controller = PageController();
  final PageController _mobileController = PageController(
    viewportFraction: .88,
  );

  @override
  void dispose() {
    _controller.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const cardHeight = 520.0;
      final width = constraints.maxWidth;
      if (width < 600) {
        return SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _mobileController,
            itemCount: widget.rooms.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _RoomCard(room: widget.rooms[index]),
            ),
          ),
        );
      }

      final columns = width < 1024 ? 2 : 3;
      final pageCount = (widget.rooms.length / columns).ceil();
      return SizedBox(
        height: cardHeight,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: pageCount,
              itemBuilder: (context, page) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 14),
                    Expanded(
                      child: page * columns + column >= widget.rooms.length
                          ? const SizedBox.shrink()
                          : _RoomCard(
                              room: widget.rooms[page * columns + column],
                            ),
                    ),
                  ],
                ],
              ),
            ),
            if (width >= 1024 && pageCount > 1) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: _RoomGalleryArrow(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: _RoomGalleryArrow(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _controller.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _RoomGalleryArrow extends StatelessWidget {
  const _RoomGalleryArrow({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: AppColors.navy.withValues(alpha: .86),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: icon == Icons.chevron_left_rounded
            ? 'Previous rooms'
            : 'Next rooms',
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.gold),
      ),
    ),
  );
}

class PropertyServicesPreview extends StatelessWidget {
  const PropertyServicesPreview({super.key});

  @override
  Widget build(BuildContext context) {
    const repository = PropertyContentRepository();
    return _RetryableSection<List<PropertyService>>(
      load: repository.getServices,
      errorMessage:
          'Service information could not be loaded. Please try again.',
      builder: (context, services) {
        if (services.isEmpty) {
          return const _InlineDataState(
            text: 'No active services are available yet.',
          );
        }
        return _HomeServicesMarquee(services: services);
      },
    );
  }
}

class _HomeServicesMarquee extends StatelessWidget {
  const _HomeServicesMarquee({required this.services});
  final List<PropertyService> services;

  @override
  Widget build(BuildContext context) {
    final chipWidth = (MediaQuery.sizeOf(context).width * .58)
        .clamp(150.0, 230.0)
        .toDouble();
    return AutoSlideServices(
      itemCount: services.length,
      itemExtent: chipWidth + 9,
      itemBuilder: (context, index) {
        final service = services[index];
        return Padding(
          padding: const EdgeInsets.only(right: 9),
          child: Container(
            width: chipWidth,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _experienceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
            ),
            child: Row(
              children: [
                Icon(
                  _serviceIcon(service.iconName),
                  color: _experienceGold,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _experienceNavy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PropertyAboutPreview extends StatelessWidget {
  const PropertyAboutPreview({super.key});

  @override
  Widget build(BuildContext context) {
    const repository = PropertyContentRepository();
    return _RetryableSection<PropertyContent?>(
      load: repository.getActiveProperty,
      errorMessage:
          'Property information could not be loaded. Please try again.',
      builder: (context, property) {
        if (property == null) {
          return const _InlineDataState(
            text: 'Property information is not available yet.',
          );
        }
        final text = property.description;
        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _experienceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _experienceLightGold.withValues(alpha: .35),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.hotel_class_outlined,
                      color: _experienceGold,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (property.name.isNotEmpty)
                          Text(
                            property.name,
                            style: const TextStyle(
                              color: _experienceNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (property.name.isNotEmpty && text.isNotEmpty)
                          const SizedBox(height: 4),
                        Text(
                          text.isNotEmpty
                              ? text
                              : 'About details are not available yet.',
                          softWrap: true,
                          style: const TextStyle(
                            color: _experienceNavy,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _AboutRings(),
            ],
          ),
        );
      },
    );
  }
}

class _AboutRings extends StatelessWidget {
  const _AboutRings();
  @override
  Widget build(BuildContext context) => FutureBuilder<AboutStats>(
    future: const PropertyContentRepository().getAboutStats(),
    builder: (context, snapshot) {
      final stats = snapshot.data;
      final rating = stats?.averageRating;
      final values = <(String, String, double)>[
        ('Rooms', stats == null ? '50+' : '${stats.rooms}+', .8),
        ('Support', '24/7', 1),
        (
          'Rating',
          rating == null ? '5★' : rating.toStringAsFixed(1),
          rating == null ? .96 : (rating / 5).clamp(0, 1),
        ),
      ];
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (label, value, progress) in values)
            Column(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 1100),
                    builder: (context, current, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: current,
                          strokeWidth: 5,
                          backgroundColor: _experienceLightGold.withValues(
                            alpha: .28,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            _experienceGold,
                          ),
                        ),
                        Text(
                          value,
                          style: const TextStyle(
                            color: _experienceNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: _experienceNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      );
    },
  );
}

class PropertyHighlightsPreview extends StatelessWidget {
  const PropertyHighlightsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WhyAtithi();
  }
}

class _RetryableSection<T> extends StatefulWidget {
  const _RetryableSection({
    required this.load,
    required this.errorMessage,
    required this.builder,
  });

  final Future<T> Function() load;
  final String errorMessage;
  final Widget Function(BuildContext, T) builder;

  @override
  State<_RetryableSection<T>> createState() => _RetryableSectionState<T>();
}

class _RetryableSectionState<T> extends State<_RetryableSection<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _InlineDataState(
          text: widget.errorMessage,
          diagnostic: _debugDataError(snapshot.error),
          onRetry: _retry,
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const _InlineLoading();
      }
      return widget.builder(context, snapshot.data as T);
    },
  );
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context) => Card(
    color: _experienceCard,
    clipBehavior: Clip.antiAlias,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: AppColors.gold.withValues(alpha: .35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => openRoomDetails(context, room),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageHeight = constraints.maxWidth * 10 / 16;
              return _RoomImageCarousel(
                imageUrls: room.imageUrls,
                height: imageHeight,
              );
            },
          ),
        ),
        _roomDetails(context),
      ],
    ),
  );

  Widget _roomDetails(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.roomName ?? 'Room',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _experienceNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${room.roomType?.isNotEmpty == true ? room.roomType : 'Room'} · ${room.capacity ?? 0} guests',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
        if (room.description?.isNotEmpty == true) ...[
          const SizedBox(height: 5),
          Text(
            room.description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '₹${NumberFormat.decimalPattern('en_IN').format(room.pricePerNight ?? 0)} / night',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _experienceNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PropertyAvailabilityBadge(
              available: room.status?.toLowerCase() == 'available',
            ),
          ],
        ),
        if (room.amenities.isNotEmpty) ...[
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: room.amenities
                .take(5)
                .map((amenity) => _PropertyAmenityChip(amenity: amenity))
                .toList(),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => openRoomDetails(context, room),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('View Details', maxLines: 1, softWrap: false),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: room.status?.toLowerCase() == 'available'
                    ? () => openRoomBooking(context, room)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _experienceNavy,
                  foregroundColor: _experienceCream,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Book Now', maxLines: 1, softWrap: false),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PropertyAvailabilityBadge extends StatelessWidget {
  const _PropertyAvailabilityBadge({required this.available});
  final bool available;
  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.navy : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        available ? 'Available' : 'Sold out',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PropertyAmenityChip extends StatelessWidget {
  const _PropertyAmenityChip({required this.amenity});
  final String amenity;
  @override
  Widget build(BuildContext context) {
    final key = amenity.trim().toLowerCase().replaceAll(' ', '_');
    const labels = {
      'wifi': 'WiFi',
      'tv': 'TV',
      'ac': 'AC',
      'mini_bar': 'Mini Bar',
      'balcony': 'Balcony',
    };
    const icons = {
      'wifi': Icons.wifi_rounded,
      'tv': Icons.tv_rounded,
      'ac': Icons.ac_unit_rounded,
      'mini_bar': Icons.local_bar_rounded,
      'balcony': Icons.balcony_rounded,
    };
    final label =
        labels[key] ??
        key
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _experienceLightGold.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icons[key] ?? Icons.check_rounded,
            size: 13,
            color: _experienceGold,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _experienceNavy),
          ),
        ],
      ),
    );
  }
}

class _RoomImageCarousel extends StatefulWidget {
  const _RoomImageCarousel({required this.imageUrls, required this.height});
  final List<String> imageUrls;
  final double height;

  @override
  State<_RoomImageCarousel> createState() => _RoomImageCarouselState();
}

class _RoomImageCarouselState extends State<_RoomImageCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _RoomImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _page = 0;
      _controller.jumpToPage(0);
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.imageUrls.length < 2) {
      _timer = null;
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseForInteraction() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), _startAutoScroll);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      _timer = null;
    } else if (_timer == null && widget.imageUrls.length > 1) {
      _startAutoScroll();
    }
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const _PropertyImage(url: null, height: 200),
      );
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _pauseForInteraction(),
            onPointerCancel: (_) => _pauseForInteraction(),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _page = index);
              },
              itemBuilder: (context, index) => _PropertyImage(
                url: widget.imageUrls[index],
                height: widget.height,
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < widget.imageUrls.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _page ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == _page
                            ? _experienceLightGold
                            : Colors.white70,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PropertyPage extends StatelessWidget {
  const _PropertyPage({
    required this.title,
    required this.child,
    this.activeRoute,
  });
  final String title;
  final Widget child;
  final String? activeRoute;

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: _experienceCream,
      appBar: AppBar(
        backgroundColor: _experienceCream,
        foregroundColor: _experienceNavy,
        title: Text(
          title,
          style: const TextStyle(
            color: _experienceNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: AppContainer(padding: EdgeInsets.zero, child: child),
      ),
    );
    if (activeRoute == null) return page;
    return AppShell(
      activeRoute: activeRoute!,
      wrapInContainer: false,
      body: page,
    );
  }
}

class _PropertyImage extends StatelessWidget {
  const _PropertyImage({required this.url, required this.height});
  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: AppNetworkImage(url: url),
    ),
  );
}

class _PageLoading extends StatelessWidget {
  const _PageLoading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: _experienceGold));
}

class _PageState extends StatelessWidget {
  const _PageState({
    required this.message,
    this.diagnostic,
    this.onRetry,
    this.isError = false,
  });
  final String message;
  final String? diagnostic;
  final VoidCallback? onRetry;
  final bool isError;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.cloud_off_outlined : Icons.hotel_outlined,
            size: 38,
            color: _experienceGold,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _experienceNavy, height: 1.45),
          ),
          if (diagnostic != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              diagnostic!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

String? _debugDataError(Object? error) {
  if (!kDebugMode || error == null) return null;
  return error.toString();
}

class _InlineDataState extends StatelessWidget {
  const _InlineDataState({required this.text, this.diagnostic, this.onRetry});
  final String text;
  final String? diagnostic;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _experienceCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _experienceLightGold.withValues(alpha: .65)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(color: _experienceNavy, height: 1.4)),
        if (diagnostic != null) ...[
          const SizedBox(height: 8),
          SelectableText(
            diagnostic!,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: CircularProgressIndicator(color: _experienceGold)),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: _experienceNavy,
      fontSize: 19,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _AnimatedSection extends StatefulWidget {
  const _AnimatedSection({required this.child, required this.delay});
  final Widget child;
  final Duration delay;

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (context, _) {
      final value = MediaQuery.disableAnimationsOf(context)
          ? 1.0
          : _animation.value;
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: widget.child,
        ),
      );
    },
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _experienceCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _experienceLightGold.withValues(alpha: .7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(color: AppColors.secondaryText, height: 1.55),
        ),
      ],
    ),
  );
}

class _WhyAtithi extends StatelessWidget {
  const _WhyAtithi();

  static const reasons = [
    ('Premium Rooms & Suites', Icons.king_bed_outlined),
    ('Safe & Secure Stay', Icons.shield_outlined),
    ('24/7 Support', Icons.support_agent_outlined),
    ('Best Rates', Icons.local_offer_outlined),
  ];

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: reasons.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      mainAxisExtent: 170,
    ),
    itemBuilder: (context, index) => _WhyFlipTile(
      index: index,
      title: reasons[index].$1,
      icon: reasons[index].$2,
      detail: const [
        'Spacious rooms with modern comfort.',
        'Your safety comes first, always.',
        'Our team is always one call away.',
        'Book direct for honest prices.',
      ][index],
    ),
  );
}

class _WhyFlipTile extends StatefulWidget {
  const _WhyFlipTile({
    required this.index,
    required this.title,
    required this.icon,
    required this.detail,
  });
  final int index;
  final String title;
  final IconData icon;
  final String detail;

  @override
  State<_WhyFlipTile> createState() => _WhyFlipTileState();
}

class _WhyFlipTileState extends State<_WhyFlipTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) return;
    Future<void>.delayed(Duration(milliseconds: widget.index * 220), () async {
      if (!mounted || _reducedMotion) return;
      await _flip.forward();
      if (mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (mounted) await _flip.reverse();
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      if (!_reducedMotion) {
        _flip.isCompleted ? _flip.reverse() : _flip.forward();
      }
    },
    child: AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final back = _flip.value >= .5;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, .001)
            ..rotateY(math.pi * _flip.value),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: back ? _experienceNavy : _experienceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _experienceLightGold.withValues(alpha: .75),
              ),
            ),
            child: back
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: _experienceLightGold),
                        const SizedBox(height: 8),
                        Text(
                          widget.detail,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _experienceCream,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Text(
                          '0${widget.index + 1}',
                          style: TextStyle(
                            color: _experienceGold.withValues(alpha: .22),
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _experienceLightGold.withValues(
                                  alpha: .3,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                color: _experienceGold,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _experienceNavy,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});
  final PropertyService service;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _experienceCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _experienceLightGold.withValues(alpha: .65)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ServiceVisual(value: service.iconName),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: const TextStyle(
                  color: _experienceNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                service.description,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ServiceVisual extends StatelessWidget {
  const _ServiceVisual({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    if (_isWebUrl(value)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          value,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Icon(_serviceIcon(value), size: 25, color: _experienceGold),
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _experienceGold,
                    ),
                  ),
                ),
        ),
      );
    }
    return Icon(_serviceIcon(value), size: 25, color: _experienceGold);
  }
}

IconData _serviceIcon(String value) {
  final name = value.toLowerCase();
  if (name.contains('wifi')) {
    return Icons.wifi_rounded;
  }
  if (name.contains('room') || name.contains('dining')) {
    return Icons.room_service_outlined;
  }
  if (name.contains('clean') || name.contains('housekeep')) {
    return Icons.cleaning_services_outlined;
  }
  if (name.contains('airport') || name.contains('transfer')) {
    return Icons.directions_car_outlined;
  }
  if (name.contains('laundry')) {
    return Icons.local_laundry_service_outlined;
  }
  if (name.contains('park')) {
    return Icons.local_parking_outlined;
  }
  if (name.contains('restaurant') || name.contains('food')) {
    return Icons.restaurant_outlined;
  }
  return Icons.support_agent_outlined;
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: _experienceCard,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: _experienceGold),
      title: Text(
        title,
        style: const TextStyle(
          color: _experienceNavy,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: AppColors.secondaryText),
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.open_in_new, size: 17, color: _experienceNavy),
    ),
  );
}

class _ContactInput extends StatelessWidget {
  const _ContactInput({
    required this.controller,
    required this.label,
    required this.validator,
    required this.maxLength,
    this.keyboardType,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final int maxLength;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _experienceCard,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _experienceLightGold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _experienceLightGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _experienceGold, width: 1.5),
        ),
      ),
    ),
  );
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Please enter your email address.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _requiredField(
  String? value, {
  required String label,
  required int maxLength,
}) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return 'Please enter your $label.';
  if (input.length > maxLength) return 'Your $label is too long.';
  return null;
}

bool _isWebUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

void _showBookingUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Online booking is not available yet. Please contact the property.',
      ),
    ),
  );
}

Future<void> _launchContact(BuildContext context, Uri uri) async {
  try {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This action is not available on this device.'),
        ),
      );
    }
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Unable to open contact action: $error\n$stackTrace');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this contact action.')),
      );
    }
  }
}
