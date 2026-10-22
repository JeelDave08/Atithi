import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/image_utils.dart';
import 'models/room.dart';
import 'theme/app_colors.dart';

const _experienceCream = Color(0xFFFBF7EF);
const _experienceCard = Color(0xFFFFFCF6);
const _experienceNavy = Color(0xFF102B46);
const _experienceGold = Color(0xFFC49A45);
const _experienceLightGold = Color(0xFFE6C786);

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

  factory PropertyRoom.fromRoom(Room room) => PropertyRoom(
    id: room.id,
    name: room.roomName ?? 'Room',
    type: room.roomType ?? '',
    description: room.description ?? '',
    pricePerNight: room.pricePerNight ?? 0,
    capacity: room.capacity ?? 0,
    amenities: room.amenities,
    imageUrls: room.imageUrls,
    availability: room.status ?? '',
  );

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
      imageUrls: _stringList(data['image_urls']),
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

  Future<List<Room>> getHomeRooms() async {
    try {
      final rows = await _supabase
          .from('rooms')
          .select()
          .eq('is_published', true)
          .order('sort_order')
          .limit(5);
      return rows.map((row) => Room.fromJson(row)).toList();
    } catch (error, stackTrace) {
      _logPropertyDataFailure('Load Home rooms', error, stackTrace);
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
          .select('*, rooms(room_name, image_urls)')
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

List<String> _stringList(Object? value) => value is Iterable
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
        return _AboutContent(property: property);
      },
    ),
  );
}

class _AboutContent extends StatelessWidget {
  const _AboutContent({required this.property});
  final PropertyContent property;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    children: [
      _PropertyImage(url: null, height: 230),
      const SizedBox(height: 24),
      _AnimatedSection(
        delay: Duration.zero,
        child: Text(
          property.name.isEmpty
              ? 'Experience Comfort, Redefined'
              : property.name,
          style: const TextStyle(
            color: _experienceNavy,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 12),
      _AnimatedSection(
        delay: const Duration(milliseconds: 80),
        child: Text(
          property.description.isNotEmpty
              ? property.description
              : 'Property introduction is not available yet.',
          style: const TextStyle(
            color: Color(0xFF4A4F5C),
            height: 1.6,
            fontSize: 15,
          ),
        ),
      ),
      const SizedBox(height: 24),
      _AnimatedSection(
        delay: const Duration(milliseconds: 220),
        child: const _WhyAtithi(),
      ),
    ],
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
            return RefreshIndicator(
              onRefresh: () => _refreshServices(property?.id),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  if (property != null) ...[
                    Text(
                      property.name,
                      style: const TextStyle(
                        color: _experienceNavy,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (var i = 0; i < services.length; i++)
                    _AnimatedSection(
                      delay: Duration(milliseconds: (i * 50).clamp(0, 400)),
                      child: _ServiceCard(service: services[i]),
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
                      child: _RoomCard(room: room),
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
          style: const TextStyle(color: Color(0xFF4A4F5C), height: 1.55),
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
          style: const TextStyle(color: Color(0xFF4A4F5C)),
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
        return RefreshIndicator(
          onRefresh: () async {
            final future = widget.repository.getMyBookings();
            setState(() => _bookings = future);
            await future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final roomData = booking['rooms'];
              final roomRow = roomData is Map
                  ? Map<String, dynamic>.from(roomData)
                  : const <String, dynamic>{};
              final room =
                  _bookingValue(roomRow, 'room_name') ??
                  _bookingValue(booking, 'room_id');
              final images = roomRow['image_urls'];
              final imageUrl = images is List && images.isNotEmpty
                  ? images.first?.toString()
                  : null;
              final status = _bookingValue(booking, 'booking_status');
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
                        width: 78,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: imageUrl == null
                              ? const ColoredBox(
                                  color: AppColors.gold,
                                  child: Icon(
                                    Icons.bed_outlined,
                                    color: AppColors.navy,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: optimizedImageUrl(imageUrl),
                                  fit: BoxFit.cover,
                                  memCacheWidth: 300,
                                  maxWidthDiskCache: 300,
                                  placeholder: (_, _) =>
                                      const ColoredBox(color: AppColors.cream),
                                  errorWidget: (_, _, _) => const ColoredBox(
                                    color: AppColors.cream,
                                    child: Icon(
                                      Icons.bed_outlined,
                                      color: AppColors.darkGold,
                                    ),
                                  ),
                                ),
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
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
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

class PropertyRoomsPreview extends StatelessWidget {
  const PropertyRoomsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    const repository = PropertyContentRepository();
    return _RetryableSection<List<Room>>(
      load: repository.getHomeRooms,
      errorMessage: 'Room information could not be loaded. Please try again.',
      builder: (context, rooms) {
        if (rooms.isEmpty) {
          return const _InlineDataState(text: 'No rooms are available yet.');
        }
        return SizedBox(
          height: 420,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length.clamp(0, 5),
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => SizedBox(
              width: 270,
              child: _RoomCard(room: PropertyRoom.fromRoom(rooms[index])),
            ),
          ),
        );
      },
    );
  }
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
        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final service in services.take(6))
              Chip(
                avatar: Icon(
                  _serviceIcon(service.iconName),
                  color: _experienceNavy,
                  size: 18,
                ),
                label: Text(service.name),
                backgroundColor: _experienceCard,
                side: const BorderSide(color: _experienceLightGold),
              ),
          ],
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
              color: _experienceLightGold.withValues(alpha: .65),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.hotel_class_outlined,
                color: _experienceGold,
                size: 27,
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }
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
  final PropertyRoom room;

  @override
  Widget build(BuildContext context) => Card(
    color: _experienceCard,
    clipBehavior: Clip.antiAlias,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0x55E6C786)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PropertyRoomDetailsScreen(room: room),
            ),
          ),
          child: _RoomImageCarousel(imageUrls: room.imageUrls, height: 175),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.name,
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
                '${room.type.isEmpty ? 'Room' : room.type} · ${room.capacity} guests',
                style: const TextStyle(color: Color(0xFF4A4F5C), fontSize: 13),
              ),
              if (room.description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  room.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4A4F5C),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Text(
                '₹${room.pricePerNight} / night',
                style: const TextStyle(
                  color: _experienceNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Availability: ${room.availability.isEmpty ? 'Not specified' : room.availability}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF4A4F5C), fontSize: 12),
              ),
              if (room.amenities.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  room.amenities.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4A4F5C),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PropertyRoomDetailsScreen(room: room),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _showBookingUnavailable(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _experienceNavy,
                      foregroundColor: _experienceCream,
                    ),
                    child: const Text('Book Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
  const _PropertyPage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
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
    body: SafeArea(child: child),
  );
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
      child: url == null || url!.isEmpty
          ? const _ImagePlaceholder()
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, _) => const _ImagePlaceholder(),
              errorWidget: (_, _, _) => const _ImagePlaceholder(),
            ),
    ),
  );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_experienceNavy, Color(0xFF416277)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
    ),
    child: Center(
      child: Icon(Icons.hotel_outlined, color: _experienceLightGold, size: 42),
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
                color: Color(0xFF4A4F5C),
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
              color: Color(0xFF4A4F5C),
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
          style: const TextStyle(color: Color(0xFF4A4F5C), height: 1.55),
        ),
      ],
    ),
  );
}

class _WhyAtithi extends StatelessWidget {
  const _WhyAtithi();

  static const _reasons = [
    ('Premium Rooms & Suites', Icons.king_bed_outlined),
    ('Safe & Secure Stay', Icons.shield_outlined),
    ('24/7 Support', Icons.support_agent_outlined),
    ('Best Rates', Icons.local_offer_outlined),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (reason, icon) in _reasons)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _experienceLightGold.withValues(alpha: .35),
                child: Icon(icon, color: _experienceGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    color: _experienceNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
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
                style: const TextStyle(color: Color(0xFF4A4F5C), height: 1.45),
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
        child: CachedNetworkImage(
          imageUrl: value,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) =>
              Icon(_serviceIcon(value), size: 25, color: _experienceGold),
          placeholder: (_, _) => const SizedBox(
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
      subtitle: Text(value, style: const TextStyle(color: Color(0xFF4A4F5C))),
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
