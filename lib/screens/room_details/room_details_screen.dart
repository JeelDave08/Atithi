import 'dart:math' as math;
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../theme/app_colors.dart';
import '../booking/booking_screen.dart';
import 'room_details_constants.dart';
import 'widgets/details_loading_skeleton.dart';
import 'widgets/room_amenities_card.dart';
import 'widgets/room_details_header.dart';
import 'widgets/room_gallery.dart';
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

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final RoomService _service = RoomService();

  Room? _room;
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _adults;
  late int _children;
  bool _loading = true;
  bool _checkingAvailability = true;
  bool? _isAvailable;
  String? _availabilityError;
  Timer? _availabilityDebounce;
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

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    final today = _dateOnly(DateTime.now());
    _checkIn = _dateOnly(widget.checkIn ?? today);
    if (_checkIn.isBefore(today)) _checkIn = today;
    _checkOut = _dateOnly(
      widget.checkOut ?? _checkIn.add(const Duration(days: 1)),
    );
    if (!_checkOut.isAfter(_checkIn)) {
      _checkOut = _checkIn.add(const Duration(days: 1));
    }
    _adults = widget.adults.clamp(1, 12);
    _children = widget.children.clamp(0, 10);

    _loadRoom();
    _refreshAvailability();
  }

  @override
  void dispose() {
    _availabilityDebounce?.cancel();
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

  Future<void> _shareRoom() async {
    final room = _room;
    if (room == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await SharePlus.instance.share(
      ShareParams(
        title: room.roomName,
        text:
            '${room.roomName} at Atithi · '
            '${_currency.format(_pricePerNight)} per night',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<bool?> _refreshAvailability({bool debounce = false}) async {
    _availabilityDebounce?.cancel();
    if (debounce) {
      ++_availabilityRequest;
      setState(() {
        _checkingAvailability = true;
        _isAvailable = null;
        _availabilityError = null;
      });
      _availabilityDebounce = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _runAvailabilityCheck();
      });
      return null;
    }
    return _runAvailabilityCheck();
  }

  Future<bool?> _runAvailabilityCheck() async {
    final request = ++_availabilityRequest;
    if (mounted) {
      setState(() {
        _checkingAvailability = true;
        _availabilityError = null;
      });
    }
    try {
      final hasConflict = await _service.hasBookingConflict(
        roomId: widget.roomId,
        checkIn: _checkIn,
        checkOut: _checkOut,
      );
      if (!mounted || request != _availabilityRequest) return null;
      setState(() {
        _isAvailable = !hasConflict;
        _checkingAvailability = false;
      });
      return !hasConflict;
    } catch (error) {
      if (!mounted || request != _availabilityRequest) return null;
      setState(() {
        _isAvailable = null;
        _checkingAvailability = false;
        _availabilityError = 'Could not check availability. Please retry.';
      });
      return null;
    }
  }

  Future<void> _book() async {
    final room = _room;
    if (room == null) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _showLoginMessage('Please log in before booking this room.');
      return;
    }
    if (_isAvailable == false) {
      _showLoginMessage(
        _availabilityError ?? 'These dates are already booked for this room.',
      );
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

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.scale(1).clamp(1.0, 1.15).toDouble();

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room = _room;

          final slivers = <Widget>[
            SliverToBoxAdapter(
              child: RoomDetailsHeader(
                roomId: widget.roomId,
                onBack: _goBack,
                onShare: _shareRoom,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
          ];

          if (_notFound) {
            slivers.add(
              SliverToBoxAdapter(child: _RoomNotFound(onBack: _goBack)),
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
                    onBack: _goBack,
                  ),
                ),
              );
            }
          } else {
            slivers.addAll([
              if (_loadError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _RefreshError(
                      onRetry: _loadRoom,
                      debugError: kDebugMode ? _debugError : null,
                    ),
                  ),
                ),

              // 1. Image Gallery with Thumbnails
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: RoomGallery(room: room),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 2. Room Title & Specs & Rating
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: RoomTitleBlock(room: room),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3. Room Amenities Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: RoomAmenitiesCard(amenities: room.amenities),
                ),
              ),
            ]);
          }

          // Bottom padding so content is never obscured by the booking panel
          slivers.add(
            SliverToBoxAdapter(
              child: SizedBox(
                height: media.padding.bottom + 110,
              ),
            ),
          );

          return Scaffold(
            backgroundColor: const Color(0xFFF8F3E7),
            body: Stack(
              children: [
                // Botanical Leaves Spray in bottom-right corner
                const Positioned(
                  right: -10,
                  bottom: -10,
                  width: 140,
                  height: 180,
                  child: IgnorePointer(
                    child: CustomPaint(painter: _BotanicalLeafPainter()),
                  ),
                ),

                SafeArea(
                  top: false,
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: CustomScrollView(slivers: slivers),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: room == null || _notFound
                ? null
                : Center(
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: StickyBookingBar(
                        total: _totalAmount,
                        pricePerNight: _pricePerNight,
                        enabled: !_checkingAvailability && _isAvailable != false,
                        onBook: _book,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _BotanicalLeafPainter extends CustomPainter {
  const _BotanicalLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          Color(0x356A7A66),
          Color(0x22556551),
          Color(0x0C435240),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0x35556551);

    final stem = Path()
      ..moveTo(size.width, size.height)
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.75,
        size.width * 0.45,
        size.height * 0.45,
        size.width * 0.1,
        0,
      );
    canvas.drawPath(stem, stemPaint);

    void drawLeaf(double cx, double cy, double rx, double ry, double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -ry)
        ..quadraticBezierTo(rx, 0, 0, ry)
        ..quadraticBezierTo(-rx, 0, 0, -ry);
      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    drawLeaf(size.width * 0.35, size.height * 0.28, 8, 22, -0.45);
    drawLeaf(size.width * 0.55, size.height * 0.52, 9, 25, -0.62);
    drawLeaf(size.width * 0.74, size.height * 0.74, 10, 24, -0.80);
    drawLeaf(size.width * 0.88, size.height * 0.90, 8, 18, -0.92);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.onRetry,
    required this.onBack,
    this.debugError,
  });

  final VoidCallback onRetry;
  final VoidCallback onBack;
  final String? debugError;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.darkGold, size: 42),
        const SizedBox(height: 12),
        const Text(
          'Could not load room',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.greyText),
        ),
        if (debugError != null) ...[
          const SizedBox(height: 8),
          Text(
            debugError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.greyText, fontSize: 11),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: onBack, child: const Text('Back')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ],
    ),
  );
}

class _RefreshError extends StatelessWidget {
  const _RefreshError({required this.onRetry, this.debugError});

  final VoidCallback onRetry;
  final String? debugError;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEDE4D4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: AppColors.darkGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            debugError != null
                ? 'Showing cached room ($debugError)'
                : 'Could not refresh latest details. Showing cached data.',
            style: const TextStyle(fontSize: 12, color: AppColors.greyText),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
