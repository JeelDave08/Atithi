import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../theme/app_colors.dart';
import '../booking/booking_screen.dart';
import 'room_details_constants.dart';
import 'widgets/about_room_card.dart';
import 'widgets/availability_card.dart';
import 'widgets/details_loading_skeleton.dart';
import 'widgets/price_breakdown_card.dart';
import 'widgets/room_amenities_card.dart';
import 'widgets/room_capacity_summary.dart';
import 'widgets/room_description.dart';
import 'widgets/room_details_header.dart';
import 'widgets/room_gallery.dart';
import 'widgets/room_price_card.dart';
import 'widgets/room_title_block.dart';
import 'widgets/sticky_booking_bar.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({
    required this.roomId,
    this.room,
    this.checkIn,
    this.checkOut,
    this.adults = 2,
    this.children = 0,
    super.key,
  });

  final String roomId;
  final Room? room;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen>
    with SingleTickerProviderStateMixin {
  final RoomService _service = RoomService();
  late final AnimationController _entranceController;
  late final Animation<double> _galleryFade;
  late final Animation<Offset> _priceSlide;

  Room? _room;
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _adults;
  late int _children;
  bool _loading = true;
  bool _favorite = false;
  bool _descriptionExpanded = false;
  bool _checkingAvailability = true;
  bool _dateConflict = false;
  bool _notFound = false;
  Object? _loadError;
  String? _debugError;
  int _availabilityRequest = 0;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int get _nights => math.max(1, _checkOut.difference(_checkIn).inDays);
  double get _pricePerNight => _room?.pricePerNight ?? 0;
  double get _totalAmount => _pricePerNight * _nights * (1 + kTaxRate);
  bool get _statusAvailable => _room?.status == 'available' && !_dateConflict;
  bool get _capacityExceeded =>
      _room?.capacity != null && _adults + _children > _room!.capacity!;
  bool get _canBook =>
      _statusAvailable && !_checkingAvailability && !_capacityExceeded;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _checkIn = _dateOnly(widget.checkIn ?? DateTime.now());
    _checkOut = _dateOnly(
      widget.checkOut ?? _checkIn.add(const Duration(days: 1)),
    );
    if (!_checkOut.isAfter(_checkIn)) {
      _checkOut = _checkIn.add(const Duration(days: 1));
    }
    _adults = widget.adults.clamp(1, 12);
    _children = widget.children.clamp(0, 10);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _galleryFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _priceSlide = Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
        );
    _entranceController.forward();

    _loadRoom();
    _loadFavorite();
    _refreshAvailability();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _debugError = null;
      _notFound = false;
    });
    try {
      final latest = await _service.fetchRoomById(widget.roomId);
      if (!mounted) return;
      setState(() {
        _room = latest;
        _notFound = latest == null;
        _loadError = null;
        _loading = false;
      });
    } catch (error, stack) {
      debugPrint('Room details load error: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _loadError = error;
        if (kDebugMode) _debugError = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _loadFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final ids = await _service.fetchFavoriteIds(user.uid);
      if (mounted) setState(() => _favorite = ids.contains(widget.roomId));
    } catch (error) {
      if (kDebugMode) debugPrint('Room favorite check failed: $error');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginMessage('Please log in to save your favorite rooms.');
      return;
    }

    final wasFavorite = _favorite;
    setState(() => _favorite = !wasFavorite);
    try {
      await _service.toggleFavorite(
        user.uid,
        widget.roomId,
        isFavorite: wasFavorite,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('Room favorite update failed: $error');
      if (!mounted) return;
      setState(() => _favorite = wasFavorite);
      _showLoginMessage('Could not update favorite. Please try again.');
    }
  }

  Future<void> _shareRoom() async {
    final room = _room;
    if (room == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await SharePlus.instance.share(
      ShareParams(
        title: room.roomName ?? 'Room at Atithi',
        text:
            '${room.roomName ?? 'Room'} at Atithi · '
            '${_currency.format(_pricePerNight)} per night',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _refreshAvailability() async {
    final request = ++_availabilityRequest;
    if (mounted) setState(() => _checkingAvailability = true);
    final hasConflict = await _service.hasBookingConflict(
      roomId: widget.roomId,
      checkIn: _checkIn,
      checkOut: _checkOut,
    );
    if (!mounted || request != _availabilityRequest) return;
    setState(() {
      _dateConflict = hasConflict;
      _checkingAvailability = false;
    });
  }

  Future<void> _pickCheckIn() async {
    final today = _dateOnly(DateTime.now());
    final lastDate = today.add(const Duration(days: 730));
    final selected = await showDatePicker(
      context: context,
      initialDate: _checkIn.isBefore(today) ? today : _checkIn,
      firstDate: today,
      lastDate: lastDate,
      builder: _datePickerTheme,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _checkIn = _dateOnly(selected);
      if (!_checkOut.isAfter(_checkIn)) {
        _checkOut = _checkIn.add(const Duration(days: 1));
      }
    });
    _refreshAvailability();
  }

  Future<void> _pickCheckOut() async {
    final firstDate = _checkIn.add(const Duration(days: 1));
    final lastDate = _checkIn.add(const Duration(days: 730));
    final selected = await showDatePicker(
      context: context,
      initialDate: _checkOut.isBefore(firstDate) ? firstDate : _checkOut,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: _datePickerTheme,
    );
    if (selected == null || !mounted) return;
    setState(() => _checkOut = _dateOnly(selected));
    _refreshAvailability();
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: AppColors.navy,
        secondary: AppColors.gold,
        surface: AppColors.cream,
        onSurface: AppColors.navy,
        onPrimary: AppColors.cream,
        error: AppColors.darkGold,
      ),
    ),
    child: child!,
  );

  void _changeAdults(int delta) {
    setState(() => _adults = (_adults + delta).clamp(1, 12));
  }

  void _changeChildren(int delta) {
    setState(() => _children = (_children + delta).clamp(0, 10));
  }

  void _book() {
    final room = _room;
    if (room == null || !_canBook) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _showLoginMessage('Please log in before booking this room.');
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BookingScreen(
          room: room,
          checkIn: _checkIn,
          checkOut: _checkOut,
          adults: _adults,
          children: _children,
        ),
      ),
    );
  }

  void _showLoginMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.scale(1).clamp(1.0, 1.15).toDouble();

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wide = width > 700;
          final contentWidth = wide ? 640.0 : width;
          final room = _room;
          final slivers = <Widget>[
            SliverToBoxAdapter(
              child: RoomDetailsHeader(
                isFavorite: _favorite,
                onBack: () => Navigator.maybePop(context),
                onFavorite: _toggleFavorite,
                onShare: _shareRoom,
              ),
            ),
          ];

          if (_notFound) {
            slivers.add(
              SliverToBoxAdapter(
                child: _RoomNotFound(onBack: () => Navigator.maybePop(context)),
              ),
            );
          } else if (room == null) {
            if (_loading) {
              slivers.add(
                const SliverToBoxAdapter(child: DetailsLoadingSkeleton()),
              );
            } else {
              slivers.add(
                SliverToBoxAdapter(
                  child: _LoadError(
                    debugError: kDebugMode ? _debugError : null,
                    onRetry: _loadRoom,
                    onBack: () => Navigator.maybePop(context),
                  ),
                ),
              );
            }
          } else {
            slivers.addAll([
              if (_loadError != null)
                SliverToBoxAdapter(
                  child: _section(
                    _RefreshError(
                      onRetry: _loadRoom,
                      debugError: kDebugMode ? _debugError : null,
                    ),
                    width,
                    contentWidth,
                  ),
                ),
              if (wide)
                SliverToBoxAdapter(
                  child: _section(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: FadeTransition(
                            opacity: _galleryFade,
                            child: RepaintBoundary(
                              child: RoomGallery(room: room),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: SlideTransition(
                            position: _priceSlide,
                            child: RoomPriceCard(pricePerNight: _pricePerNight),
                          ),
                        ),
                      ],
                    ),
                    width,
                    contentWidth,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: _section(
                    FadeTransition(
                      opacity: _galleryFade,
                      child: RepaintBoundary(child: RoomGallery(room: room)),
                    ),
                    width,
                    contentWidth,
                  ),
                ),
              SliverToBoxAdapter(
                child: _section(
                  RoomTitleBlock(room: room),
                  width,
                  contentWidth,
                ),
              ),
              if (!wide)
                SliverToBoxAdapter(
                  child: _section(
                    SlideTransition(
                      position: _priceSlide,
                      child: RoomPriceCard(pricePerNight: _pricePerNight),
                    ),
                    width,
                    contentWidth,
                  ),
                ),
              SliverToBoxAdapter(
                child: _section(
                  RoomDescription(
                    description: room.description ?? '',
                    expanded: _descriptionExpanded,
                    onToggle: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    ),
                  ),
                  width,
                  contentWidth,
                ),
              ),
              SliverToBoxAdapter(
                child: _section(
                  RoomAmenitiesCard(amenities: room.amenities),
                  width,
                  contentWidth,
                ),
              ),
              SliverToBoxAdapter(
                child: _section(
                  AboutRoomCard(description: room.description ?? ''),
                  width,
                  contentWidth,
                ),
              ),
              SliverToBoxAdapter(
                child: _section(
                  AvailabilityCard(
                    checkIn: _checkIn,
                    checkOut: _checkOut,
                    nights: _nights,
                    adults: _adults,
                    children: _children,
                    unitsLeft: room.unitsLeft,
                    available: _statusAvailable,
                    checking: _checkingAvailability,
                    compact: !wide,
                    onCheckIn: _pickCheckIn,
                    onCheckOut: _pickCheckOut,
                    onAdultsChange: _changeAdults,
                    onChildrenChange: _changeChildren,
                  ),
                  width,
                  contentWidth,
                ),
              ),
              SliverToBoxAdapter(
                child: _section(
                  RoomCapacitySummary(
                    capacity: room.capacity,
                    bedInfo: room.bedInfo,
                    guestCount: _adults + _children,
                  ),
                  width,
                  contentWidth,
                ),
              ),
              SliverToBoxAdapter(
                child: _section(
                  PriceBreakdownCard(
                    pricePerNight: _pricePerNight,
                    nights: _nights,
                  ),
                  width,
                  contentWidth,
                ),
              ),
            ]);
          }

          slivers.add(
            SliverToBoxAdapter(
              child: SizedBox(
                height: media.padding.bottom + (width < 400 ? 166 : 100) + 16,
              ),
            ),
          );

          return Scaffold(
            backgroundColor: AppColors.cream,
            body: CustomScrollView(slivers: slivers),
            bottomNavigationBar: room == null || _notFound
                ? null
                : StickyBookingBar(
                    total: _totalAmount,
                    enabled: _canBook,
                    onBook: _book,
                  ),
          );
        },
      ),
    );
  }

  Widget _section(Widget child, double width, double contentWidth) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width > 700 ? 0 : 16),
          child: child,
        ),
      ),
    ),
  );
}

class _RoomNotFound extends StatelessWidget {
  const _RoomNotFound({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.hotel_outlined, color: AppColors.darkGold, size: 42),
        const SizedBox(height: 12),
        const Text(
          'Room not found',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This room is no longer available to view.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.greyText),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go back'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.gold),
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.debugError,
    required this.onRetry,
    required this.onBack,
  });

  final String? debugError;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(26),
    child: Column(
      children: [
        const Text(
          'We could not load this room.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.navy, fontSize: 17),
        ),
        if (debugError != null) ...[
          const SizedBox(height: 8),
          SelectableText(
            debugError!,
            maxLines: 3,
            style: const TextStyle(color: AppColors.greyText, fontSize: 10),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton(onPressed: onBack, child: const Text('Go back')),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ],
    ),
  );
}

class _RefreshError extends StatelessWidget {
  const _RefreshError({required this.onRetry, required this.debugError});
  final VoidCallback onRetry;
  final String? debugError;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Showing saved room details. Refresh failed.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.greyText, fontSize: 12),
              ),
              if (debugError != null)
                SelectableText(
                  debugError!,
                  maxLines: 3,
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
