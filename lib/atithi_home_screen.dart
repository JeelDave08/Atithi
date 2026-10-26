import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'core/navigation/app_shell.dart';
import 'models/stay_search.dart';
import 'providers/stay_search_provider.dart';
import 'providers/rooms_provider.dart';
import 'core/responsive/breakpoints.dart';
import 'features/home/widgets/reveal_on_scroll.dart';
import 'property_experience.dart';
import 'theme/app_colors.dart';
import 'widgets/app_menu_button.dart';

const _cream = AppColors.cream;
const _cardCream = AppColors.surface;
const _navy = AppColors.navy;
const _gold = AppColors.gold;
const _secondaryText = AppColors.secondaryText;

class AtithiHomeScreen extends ConsumerStatefulWidget {
  const AtithiHomeScreen({super.key});

  @override
  ConsumerState<AtithiHomeScreen> createState() => _AtithiHomeScreenState();
}

class _AtithiHomeScreenState extends ConsumerState<AtithiHomeScreen> {
  late DateTime _checkIn = _dateOnly(DateTime.now());
  late DateTime _checkOut = _dateOnly(DateTime.now())
      .add(const Duration(days: 1));
  int _adults = 2;
  int _children = 0;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _selectCheckIn() async {
    final today = _dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _checkIn.isBefore(today) ? today : _checkIn,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      builder: _datePickerTheme,
    );
    if (selected == null) return;
    setState(() {
      _checkIn = _dateOnly(selected);
      if (!_checkOut.isAfter(_checkIn)) {
        _checkOut = _checkIn.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _selectCheckOut() async {
    final firstCheckout = _checkIn.add(const Duration(days: 1));
    final selected = await showDatePicker(
      context: context,
      initialDate: _checkOut.isBefore(firstCheckout)
          ? firstCheckout
          : _checkOut,
      firstDate: firstCheckout,
      lastDate: _checkIn.add(const Duration(days: 730)),
      builder: _datePickerTheme,
    );
    if (selected == null) return;
    setState(() => _checkOut = _dateOnly(selected));
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: _navy,
        onPrimary: _cream,
        surface: _cream,
        onSurface: _navy,
      ),
    ),
    child: child!,
  );

  void _openRoomListing() {
    if (!_checkOut.isAfter(_checkIn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out must be after check-in.')),
      );
      return;
    }
    ref
        .read(staySearchProvider.notifier)
        .save(
          StaySearch(
            checkIn: _checkIn,
            checkOut: _checkOut,
            adults: _adults,
            children: _children,
          ),
        );
    context.push(
      '/rooms',
      extra: RoomSearchSelection(
        checkIn: _checkIn,
        checkOut: _checkOut,
        adults: _adults,
        children: _children,
      ),
    );
  }

  void _changeCount({required bool adults, required int change}) {
    final maxGuests =
        ref
            .read(roomsProvider)
            .valueOrNull
            ?.fold<int>(
              2,
              (m, room) => room.maxGuests > m ? room.maxGuests : m,
            ) ??
        12;
    if (_adults + _children + change > maxGuests) return;
    setState(() {
      if (adults) {
        _adults = (_adults + change).clamp(1, 12);
      } else {
        _children = (_children + change).clamp(0, 10);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activeRoute: '/home',
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) => context.isMobile
                    ? const _HomeHeader()
                    : const SizedBox(height: 12),
              ),
            ),
            SliverToBoxAdapter(child: HeroSection(onTap: _openRoomListing)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: BookingCard(
                    checkIn: _checkIn,
                    checkOut: _checkOut,
                    adults: _adults,
                    children: _children,
                    maxGuests:
                        ref
                            .watch(roomsProvider)
                            .valueOrNull
                            ?.fold<int>(
                              2,
                              (m, room) =>
                                  room.maxGuests > m ? room.maxGuests : m,
                            ) ??
                        12,
                    onCheckInTap: _selectCheckIn,
                    onCheckOutTap: _selectCheckOut,
                    onAdultsChange: (value) =>
                        _changeCount(adults: true, change: value),
                    onChildrenChange: (value) =>
                        _changeCount(adults: false, change: value),
                    onSearch: _openRoomListing,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 0),
                child: _TrustStrip(),
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Explore Atithi',
                child: _QuickAccessRow(
                  onTap: (title) {
                    switch (title) {
                      case 'Our Rooms':
                        _openRoomListing();
                      case 'Amenities':
                        context.push('/services');
                      case 'Services':
                        context.push('/services');
                      case 'About Us':
                        context.push('/about');
                      case 'Contact Us':
                        context.push('/contact');
                    }
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Our Rooms',
                actionLabel: 'View All',
                onAction: _openRoomListing,
                child: const PropertyRoomsPreview(),
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Our Services',
                actionLabel: 'View All',
                onAction: () => context.push('/services'),
                child: const PropertyServicesPreview(),
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                title: 'About Atithi',
                actionLabel: 'Learn More',
                onAction: () => context.push('/about'),
                child: const PropertyAboutPreview(),
              ),
            ),
            const SliverToBoxAdapter(child: WhyChooseAtithiSection()),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Contact Us',
                actionLabel: 'Get in Touch',
                onAction: () => context.push('/contact'),
                child: _ContactCard(onTap: () => context.push('/contact')),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 10, 2, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ATITHI',
              style: GoogleFonts.playfairDisplay(
                color: _navy,
                fontSize: 32,
                height: 1.0,
                letterSpacing: 2.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const _OrnamentDivider(),
          ],
        ),
        const Spacer(),
        const AppMenuButton(),
      ],
    ),
  );
}

class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 116,
    height: 12,
    child: CustomPaint(painter: _FlowerOrnamentPainter()),
  );
}

class _FlowerOrnamentPainter extends CustomPainter {
  const _FlowerOrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _gold
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = _gold
      ..style = PaintingStyle.fill;

    final cy = size.height / 2;
    final cx = size.width / 2;

    // Horizontal accent lines
    canvas.drawLine(Offset(0, cy), Offset(cx - 12, cy), linePaint);
    canvas.drawLine(Offset(cx + 12, cy), Offset(size.width, cy), linePaint);

    // 4-petal flower emblem
    // Top petal
    final topPetal = Path()
      ..moveTo(cx, cy - 1)
      ..lineTo(cx - 2.5, cy - 4)
      ..lineTo(cx, cy - 6.5)
      ..lineTo(cx + 2.5, cy - 4)
      ..close();
    canvas.drawPath(topPetal, fillPaint);

    // Bottom petal
    final bottomPetal = Path()
      ..moveTo(cx, cy + 1)
      ..lineTo(cx - 2.5, cy + 4)
      ..lineTo(cx, cy + 6.5)
      ..lineTo(cx + 2.5, cy + 4)
      ..close();
    canvas.drawPath(bottomPetal, fillPaint);

    // Left petal
    final leftPetal = Path()
      ..moveTo(cx - 1, cy)
      ..lineTo(cx - 4, cy - 2.5)
      ..lineTo(cx - 6.5, cy)
      ..lineTo(cx - 4, cy + 2.5)
      ..close();
    canvas.drawPath(leftPetal, fillPaint);

    // Right petal
    final rightPetal = Path()
      ..moveTo(cx + 1, cy)
      ..lineTo(cx + 4, cy - 2.5)
      ..lineTo(cx + 6.5, cy)
      ..lineTo(cx + 4, cy + 2.5)
      ..close();
    canvas.drawPath(rightPetal, fillPaint);

    // Center small diamond
    final centerDiamond = Path()
      ..moveTo(cx, cy - 1.8)
      ..lineTo(cx + 1.8, cy)
      ..lineTo(cx, cy + 1.8)
      ..lineTo(cx - 1.8, cy)
      ..close();
    canvas.drawPath(centerDiamond, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _FlowerOrnamentPainter oldDelegate) => false;
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = context.responsive(
          mobile: 4 / 3,
          tablet: 16 / 9,
          desktop: 21 / 9,
        );
        final heroHeight = math.min(480.0, constraints.maxWidth / ratio);
        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: heroHeight,
              width: constraints.maxWidth,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  ColoredBox(
                    color: _cream,
                    child: Image.asset(
                      'assets/images/heritage_hero_bg.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned(
                    top: context.isMobile ? 20 : 30,
                    left: context.isMobile ? 18 : 36,
                    child: Text(
                      'More than\njust a stay',
                      style: GoogleFonts.playfairDisplay(
                        color: _navy,
                        fontSize: context.responsive(
                          mobile: 26,
                          tablet: 32,
                          desktop: 40,
                        ),
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.maxGuests,
    required this.onCheckInTap,
    required this.onCheckOutTap,
    required this.onAdultsChange,
    required this.onChildrenChange,
    required this.onSearch,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int maxGuests;
  final VoidCallback onCheckInTap;
  final VoidCallback onCheckOutTap;
  final ValueChanged<int> onAdultsChange;
  final ValueChanged<int> onChildrenChange;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final dateRow = Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Check-in',
                date: checkIn,
                onTap: onCheckInTap,
              ),
            ),
            Container(
              width: 1,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: _gold.withValues(alpha: 0.35),
            ),
            Expanded(
              child: _DateField(
                label: 'Check-out',
                date: checkOut,
                onTap: onCheckOutTap,
              ),
            ),
          ],
        );
        final guestsRow = Row(
          children: [
            Expanded(
              child: _GuestCounter(
                iconWidget: const Icon(
                  Icons.person_outline_rounded,
                  color: _navy,
                  size: 26,
                ),
                label: 'Adults',
                count: adults,
                canIncrement: adults + children < maxGuests,
                onDecrement: () => onAdultsChange(-1),
                onIncrement: () => onAdultsChange(1),
              ),
            ),
            Container(
              width: 1,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: _gold.withValues(alpha: 0.35),
            ),
            Expanded(
              child: _GuestCounter(
                iconWidget: const _ChildFaceIcon(size: 26, color: _navy),
                label: 'Children',
                count: children,
                canIncrement: adults + children < maxGuests,
                onDecrement: () => onChildrenChange(-1),
                onIncrement: () => onChildrenChange(1),
              ),
            ),
          ],
        );
        final searchButton = SizedBox(
          width: compact
              ? double.infinity
              : 212 * MediaQuery.textScalerOf(context).scale(16) / 16,
          height: 56,
          child: Material(
            color: _navy,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onSearch,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Find a stay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compact ? double.infinity : 1000,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                color: _cardCream,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1810284B),
                    blurRadius: 28,
                    spreadRadius: 0,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: compact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        dateRow,
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          color: _gold.withValues(alpha: 0.35),
                        ),
                        guestsRow,
                        if (adults + children >= maxGuests)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Max $maxGuests guests per room',
                              style: const TextStyle(
                                color: _secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        searchButton,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _DateField(
                            label: 'Check-in',
                            date: checkIn,
                            onTap: onCheckInTap,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _DateField(
                            label: 'Check-out',
                            date: checkOut,
                            onTap: onCheckOutTap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: _GuestCounter(
                            iconWidget: const Icon(
                              Icons.person_outline_rounded,
                              color: _navy,
                              size: 24,
                            ),
                            label: 'Adults',
                            count: adults,
                            canIncrement: adults + children < maxGuests,
                            onDecrement: () => onAdultsChange(-1),
                            onIncrement: () => onAdultsChange(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: _GuestCounter(
                            iconWidget: const _ChildFaceIcon(
                              size: 24,
                              color: _navy,
                            ),
                            label: 'Children',
                            count: children,
                            canIncrement: adults + children < maxGuests,
                            onDecrement: () => onChildrenChange(-1),
                            onIncrement: () => onChildrenChange(1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        searchButton,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, color: _navy, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEE, d MMM').format(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GuestCounter extends StatelessWidget {
  const _GuestCounter({
    required this.iconWidget,
    required this.label,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
    this.canIncrement = true,
  });

  final Widget iconWidget;
  final String label;
  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final counter = Row(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _CircleRoundButton(icon: Icons.remove, onTap: onDecrement),
          const SizedBox(width: 4),
          _CircleRoundButton(
            icon: Icons.add,
            onTap: onIncrement,
            enabled: canIncrement,
          ),
        ],
      );
      final labelRow = Row(
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: constraints.maxWidth < 150
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [labelRow, counter],
              )
            : Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        counter,
                      ],
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _CircleRoundButton extends StatelessWidget {
  const _CircleRoundButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Material(
    color: enabled ? const Color(0xFFEFE8D8) : const Color(0xFFE5E0D6),
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: Icon(icon, size: 16, color: _navy)),
      ),
    ),
  );
}

class _ChildFaceIcon extends StatelessWidget {
  const _ChildFaceIcon({this.size = 24, this.color = _navy});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _ChildFacePainter(color: color)),
  );
}

class _ChildFacePainter extends CustomPainter {
  const _ChildFacePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.5, size.height * 0.53);
    final radius = size.width * 0.35;

    // Face circle
    canvas.drawCircle(center, radius, stroke);

    // Left ear
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx - radius, center.dy),
        radius: 2.8,
      ),
      -math.pi / 2,
      math.pi,
      false,
      stroke,
    );
    // Right ear
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx + radius, center.dy),
        radius: 2.8,
      ),
      -math.pi / 2,
      math.pi,
      false,
      stroke,
    );

    // Eyes
    canvas.drawCircle(Offset(center.dx - 3.6, center.dy - 1.5), 1.2, fill);
    canvas.drawCircle(Offset(center.dx + 3.6, center.dy - 1.5), 1.2, fill);

    // Friendly smile
    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 2),
      width: 7,
      height: 4.8,
    );
    canvas.drawArc(smileRect, 0.25, math.pi - 0.5, false, stroke);

    // Top hair curl
    final hair = Path()
      ..moveTo(center.dx - 2, center.dy - radius)
      ..cubicTo(
        center.dx - 4,
        center.dy - radius - 5,
        center.dx + 3.5,
        center.dy - radius - 4.5,
        center.dx + 0.5,
        center.dy - radius + 1,
      );
    canvas.drawPath(hair, stroke);
  }

  @override
  bool shouldRepaint(covariant _ChildFacePainter oldDelegate) =>
      color != oldDelegate.color;
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: _cardCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.star_rounded,
              label: 'Rating',
              value: '4.8',
            ),
          ),
          Expanded(
            child: _TrustItem(
              icon: Icons.support_agent_rounded,
              label: 'Support',
              value: '24/7',
            ),
          ),
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_user_outlined,
              label: 'Cancellation',
              value: 'Free',
            ),
          ),
        ],
      ),
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: _gold, size: 18),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        style: const TextStyle(
          color: _navy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _secondaryText, fontSize: 10),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 26, 0, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RevealOnScroll(
          slideFrom: const Offset(-.15, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: _navy,
                    fontSize: context.responsive(
                      mobile: 26,
                      tablet: 32,
                      desktop: 40,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: _gold,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 38,
            height: 3,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class WhyChooseAtithiSection extends StatelessWidget {
  const WhyChooseAtithiSection({super.key});

  @override
  Widget build(BuildContext context) => const _Section(
    title: 'Why Choose Atithi?',
    child: PropertyHighlightsPreview(),
  );
}

class _IconLabel {
  const _IconLabel(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _QuickAccessRow extends StatefulWidget {
  const _QuickAccessRow({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  State<_QuickAccessRow> createState() => _QuickAccessRowState();
}

class _QuickAccessRowState extends State<_QuickAccessRow> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    const items = [
      _IconLabel(Icons.bed_outlined, 'Our Rooms'),
      _IconLabel(Icons.spa_outlined, 'Amenities'),
      _IconLabel(Icons.room_service_outlined, 'Services'),
      _IconLabel(Icons.info_outline_rounded, 'About Us'),
      _IconLabel(Icons.phone_in_talk_outlined, 'Contact Us'),
    ];
    Widget item(int index) => SizedBox(
      width: context.isMobile ? 67 : 104,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() => _selected = index);
          widget.onTap(items[index].label);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _selected == index ? _navy : _cardCream,
                border: Border.all(color: _gold, width: 1.2),
              ),
              child: Transform.rotate(
                angle: _selected == index ? -.14 : 0,
                child: Icon(
                  items[index].icon,
                  color: _selected == index ? _gold : _navy,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              items[index].label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _navy,
                fontSize: context.isMobile ? 10 : 12,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
    if (context.isMobile) {
      return SizedBox(
        height: 98,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, index) => item(index),
        ),
      );
    }
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 12,
        children: [
          for (var index = 0; index < items.length; index++) item(index),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: _navy,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _gold.withValues(alpha: 0.5)),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -24,
          top: -40,
          child: Container(
            width: 115,
            height: 115,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _gold.withValues(alpha: 0.12),
                width: 2,
              ),
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: -20,
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _gold.withValues(alpha: 0.12),
                width: 2,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.phone_in_talk_rounded, color: _gold, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'View property contact details or send a message to the team.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Get in Touch',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: _cream,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
              onTap: () => context.go('/home'),
            ),
            _NavItem(
              icon: Icons.bed_outlined,
              label: 'Rooms',
              selected: false,
              onTap: () => context.go('/rooms'),
            ),
            _NavItem(
              icon: Icons.calendar_month_outlined,
              label: 'Bookings',
              selected: false,
              onTap: () => context.go('/bookings'),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: false,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _navy, size: 25),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: selected ? _gold : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ),
  );
}

class AtithiDestinationScreen extends StatelessWidget {
  const AtithiDestinationScreen({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    appBar: AppBar(
      backgroundColor: _cream,
      foregroundColor: _navy,
      title: Text(title),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _cardCream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: 0.6)),
          ),
          child: Text(
            description,
            style: const TextStyle(color: _navy, fontSize: 16, height: 1.6),
          ),
        ),
      ),
    ),
  );
}
