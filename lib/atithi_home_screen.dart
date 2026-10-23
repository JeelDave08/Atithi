import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'theme/app_colors.dart';
import 'features/home/widgets/reveal_on_scroll.dart';
import 'property_experience.dart';

const _cream = AppColors.cream;
const _cardCream = AppColors.surface;
const _navy = AppColors.navy;
const _gold = AppColors.gold;
const _lightGold = AppColors.gold;
const _mainText = AppColors.navy;

class AtithiHomeScreen extends StatefulWidget {
  const AtithiHomeScreen({super.key});

  @override
  State<AtithiHomeScreen> createState() => _AtithiHomeScreenState();
}

class _AtithiHomeScreenState extends State<AtithiHomeScreen> {
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
        onSurface: _mainText,
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
    setState(() {
      if (adults) {
        _adults = (_adults + change).clamp(1, 12);
      } else {
        _children = (_children + change).clamp(0, 10);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    body: SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHeader(
              onMenuSelected: (item) {
                switch (item) {
                  case 'About Atithi':
                    context.push('/about');
                  case 'Contact Us':
                    context.push('/contact');
                  case 'Our Services':
                    context.push('/services');
                }
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Text(
                'More than just a stay',
                style: GoogleFonts.playfairDisplay(
                  color: _navy,
                  fontSize: 29,
                  height: 1.08,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: HeroSection(onTap: _openRoomListing),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: BookingCard(
                  checkIn: _checkIn,
                  checkOut: _checkOut,
                  adults: _adults,
                  children: _children,
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
          const SliverToBoxAdapter(child: _TrustStrip()),
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
          SliverToBoxAdapter(
            child: _Section(
              title: 'Why Choose Atithi?',
              child: const PropertyHighlightsPreview(),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Contact Us',
              actionLabel: 'Get in Touch',
              onAction: () => context.push('/contact'),
              child: _ContactCard(onTap: () => context.push('/contact')),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 100),
          ),
        ],
      ),
    ),
    bottomNavigationBar: const BottomNav(),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onMenuSelected});
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ATITHI',
              style: GoogleFonts.playfairDisplay(
                color: _navy,
                fontSize: 31,
                height: 1,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            const _OrnamentDivider(),
          ],
        ),
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: 'Open menu',
          onSelected: onMenuSelected,
          color: _cardCream,
          icon: const Icon(Icons.menu_rounded, color: _navy, size: 27),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'About Atithi', child: Text('About Atithi')),
            PopupMenuItem(value: 'Our Services', child: Text('Our Services')),
            PopupMenuItem(value: 'Contact Us', child: Text('Contact Us')),
          ],
        ),
      ],
    ),
  );
}

class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 124,
    child: Row(
      children: [
        Expanded(
          child: Container(height: 1, color: _gold.withValues(alpha: .65)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 7, height: 7, color: _gold),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: _gold.withValues(alpha: .65)),
        ),
      ],
    ),
  );
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = (constraints.maxWidth * .76)
          .clamp(230.0, 360.0)
          .toDouble();
      return Semantics(
        image: true,
        label: 'Palace viewed through a heritage archway with a lantern and plants',
        child: Material(
          color: _cardCream,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: const _HeritageArchPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _HeritageArchPainter extends CustomPainter {
  const _HeritageArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final arch = Path()
      ..moveTo(w * .11, h)
      ..lineTo(w * .11, h * .42)
      ..cubicTo(w * .11, h * .12, w * .89, h * .12, w * .89, h * .42)
      ..lineTo(w * .89, h)
      ..close();
    final outer = Paint()..color = _navy;
    canvas.drawPath(arch, outer);
    final innerArch = Path()
      ..moveTo(w * .16, h)
      ..lineTo(w * .16, h * .43)
      ..cubicTo(w * .16, h * .17, w * .84, h * .17, w * .84, h * .43)
      ..lineTo(w * .84, h)
      ..close();
    canvas.drawPath(innerArch, Paint()..color = const Color(0xFFF0DFBD));

    canvas.save();
    canvas.clipPath(innerArch);
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_cardCream, Color(0xFFE8D6AE)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    final distantHills = Path()
      ..moveTo(w * .14, h * .76)
      ..quadraticBezierTo(w * .36, h * .44, w * .57, h * .7)
      ..quadraticBezierTo(w * .73, h * .5, w * .87, h * .73)
      ..lineTo(w * .87, h)
      ..lineTo(w * .14, h)
      ..close();
    canvas.drawPath(
      distantHills,
      Paint()..color = _gold.withValues(alpha: .58),
    );
    final hills = Path()
      ..moveTo(w * .14, h * .83)
      ..quadraticBezierTo(w * .36, h * .61, w * .57, h * .81)
      ..quadraticBezierTo(w * .75, h * .63, w * .87, h * .8)
      ..lineTo(w * .87, h)
      ..lineTo(w * .14, h)
      ..close();
    canvas.drawPath(hills, Paint()..color = _navy.withValues(alpha: .75));
    _drawPalace(canvas, w, h);
    canvas.restore();

    final trim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = _gold;
    canvas.drawPath(arch, trim);
    final innerTrim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _cardCream.withValues(alpha: .8);
    canvas.drawPath(innerArch, innerTrim);
    _drawLantern(canvas, w * .16, h * .49, math.min(w, h) * .095);
    _drawPlant(canvas, w * .24, h * .92, math.min(w, h) * .19);
    _drawBananaLeaves(canvas, w * .12, h * .94, math.min(w, h) * .26);
  }

  void _drawPalace(Canvas canvas, double w, double h) {
    final palace = Paint()..color = _navy;
    final gold = Paint()..color = _gold;
    final baseY = h * .77;
    canvas.drawRect(Rect.fromLTWH(w * .39, h * .58, w * .24, h * .19), palace);
    canvas.drawRect(Rect.fromLTWH(w * .34, h * .67, w * .34, h * .1), gold);
    canvas.drawRect(Rect.fromLTWH(w * .37, h * .69, w * .28, h * .08), palace);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .44, h * .49, w * .14, h * .1),
        const Radius.circular(24),
      ),
      palace,
    );
    canvas.drawCircle(Offset(w * .51, h * .49), w * .055, gold);
    canvas.drawRect(Rect.fromLTWH(w * .47, h * .51, w * .08, h * .1), palace);
    for (final x in [w * .41, w * .48, w * .55, w * .61]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, h * .61, w * .025, h * .045),
          const Radius.circular(4),
        ),
        Paint()..color = _gold,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(w * .45, baseY - h * .045, w * .12, h * .045),
      gold,
    );
  }

  void _drawLantern(Canvas canvas, double x, double y, double radius) {
    final glow = Paint()..color = _gold.withValues(alpha: .24);
    canvas.drawCircle(Offset(x, y), radius * .95, glow);
    final metal = Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(x, y - radius * 1.5),
      Offset(x, y - radius * .65),
      metal,
    );
    final body = Rect.fromCenter(
      center: Offset(x, y),
      width: radius,
      height: radius * 1.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4)),
      metal,
    );
    canvas.drawLine(
      Offset(body.left + 4, body.top + 3),
      Offset(body.left + 4, body.bottom - 3),
      metal,
    );
    canvas.drawLine(
      Offset(body.right - 4, body.top + 3),
      Offset(body.right - 4, body.bottom - 3),
      metal,
    );
    canvas.drawRect(body.deflate(radius * .18), Paint()..color = _gold);
    canvas.drawLine(
      Offset(x - radius * .65, body.top),
      Offset(x + radius * .65, body.top),
      metal,
    );
    canvas.drawLine(
      Offset(x - radius * .65, body.bottom),
      Offset(x + radius * .65, body.bottom),
      metal,
    );
  }

  void _drawPlant(Canvas canvas, double x, double y, double scale) {
    final leaf = Paint()..color = _navy;
    canvas.drawLine(
      Offset(x, y - scale * .2),
      Offset(x, y - scale),
      Paint()
        ..color = _gold
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 5; i++) {
      final direction = i - 2;
      final path = Path()
        ..moveTo(x, y - scale * .34)
        ..quadraticBezierTo(
          x + direction * scale * .18,
          y - scale * .78,
          x + direction * scale * .28,
          y - scale * (1.15 - direction.abs() * .1),
        )
        ..quadraticBezierTo(
          x + direction * scale * .09,
          y - scale * .67,
          x,
          y - scale * .34,
        )
        ..close();
      canvas.drawPath(path, leaf);
    }
    final pot = Path()
      ..moveTo(x - scale * .38, y - scale * .22)
      ..lineTo(x + scale * .38, y - scale * .22)
      ..lineTo(x + scale * .28, y + scale * .3)
      ..lineTo(x - scale * .28, y + scale * .3)
      ..close();
    canvas.drawPath(pot, Paint()..color = _gold);
    canvas.drawLine(
      Offset(x - scale * .38, y - scale * .22),
      Offset(x + scale * .38, y - scale * .22),
      Paint()
        ..color = _navy
        ..strokeWidth = 3,
    );
  }

  void _drawBananaLeaves(Canvas canvas, double x, double y, double scale) {
    for (var i = 0; i < 5; i++) {
      final angle = -1.15 + i * .48;
      final end = Offset(
        x + math.cos(angle) * scale,
        y + math.sin(angle) * scale,
      );
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + math.cos(angle - .35) * scale * .6,
          y + math.sin(angle - .35) * scale * .6,
          end.dx,
          end.dy,
        )
        ..quadraticBezierTo(
          x + math.cos(angle + .3) * scale * .5,
          y + math.sin(angle + .3) * scale * .5,
          x,
          y,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = i.isEven ? _navy : _gold);
      canvas.drawLine(
        Offset(x, y),
        end,
        Paint()
          ..color = _cardCream.withValues(alpha: .6)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeritageArchPainter oldDelegate) => false;
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: _cardCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: .32)),
      ),
      child: Row(
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
      Icon(icon, color: _gold, size: 17),
      const SizedBox(height: 3),
      if (label == 'Rating')
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 4.8),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 900),
          builder: (context, count, _) => Text(
            count.toStringAsFixed(1),
            maxLines: 1,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        )
      else
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
        style: const TextStyle(color: _mainText, fontSize: 9),
      ),
    ],
  );
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
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
  final VoidCallback onCheckInTap;
  final VoidCallback onCheckOutTap;
  final ValueChanged<int> onAdultsChange;
  final ValueChanged<int> onChildrenChange;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 370;
      return Container(
        padding: EdgeInsets.all(compact ? 13 : 16),
        decoration: BoxDecoration(
          color: _cardCream,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gold.withValues(alpha: .35)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0B1F3A),
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DateChoice(
                    label: 'Check-in',
                    date: checkIn,
                    onTap: onCheckInTap,
                    compact: compact,
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  color: _gold.withValues(alpha: .35),
                ),
                Expanded(
                  child: _DateChoice(
                    label: 'Check-out',
                    date: checkOut,
                    onTap: onCheckOutTap,
                    compact: compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GuestStepper(
                    label: 'Adults',
                    count: adults,
                    icon: Icons.person_outline_rounded,
                    onChanged: onAdultsChange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GuestStepper(
                    label: 'Children',
                    count: children,
                    icon: Icons.child_care_outlined,
                    onChanged: onChildrenChange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onSearch,
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: _cream,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Find a stay  →',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DateChoice extends StatelessWidget {
  const _DateChoice({
    required this.label,
    required this.date,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: _navy,
              size: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEE, d MMM').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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

class GuestStepper extends StatelessWidget {
  const GuestStepper({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final int count;
  final IconData icon;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _gold, size: 19),
      const SizedBox(width: 5),
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
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      _CounterButton(
        icon: Icons.remove,
        tooltip: 'Decrease $label',
        onTap: () => onChanged(-1),
      ),
      const SizedBox(width: 4),
      _CounterButton(
        icon: Icons.add,
        tooltip: 'Increase $label',
        onTap: () => onChanged(1),
      ),
    ],
  );
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    height: 32,
    child: IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 16, color: _navy),
      style: IconButton.styleFrom(
        backgroundColor: _gold.withValues(alpha: .24),
        shape: const CircleBorder(),
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
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
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
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
                    color: _mainText,
                    fontSize: 22,
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
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) => SizedBox(
          width: 67,
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
                    border: Border.all(color: _lightGold, width: 1.2),
                  ),
                  child: Transform.rotate(
                    angle: _selected == index ? -.14 : 0,
                    child: Icon(
                      items[index].icon,
                      color: _selected == index ? _lightGold : _navy,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  items[index].label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _mainText,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      border: Border.all(color: _lightGold.withValues(alpha: .5)),
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
                color: _lightGold.withValues(alpha: .12),
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
                color: _lightGold.withValues(alpha: .12),
                width: 2,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  color: _lightGold,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
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
                  backgroundColor: _lightGold,
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
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
    decoration: BoxDecoration(
      color: _cardCream,
      borderRadius: BorderRadius.circular(32),
      boxShadow: const [
        BoxShadow(
          color: Color(0x160F2943),
          blurRadius: 12,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
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
              onTap: () => context.go('/rooms'),
            ),
            _NavItem(
              icon: Icons.event_note_outlined,
              label: 'Bookings',
              onTap: () => context.go('/bookings'),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
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
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _navy,
              size: 21,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: _navy,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 20 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: selected ? _gold : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
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
            border: Border.all(color: _lightGold.withValues(alpha: .6)),
          ),
          child: Text(
            description,
            style: const TextStyle(color: _mainText, fontSize: 16, height: 1.6),
          ),
        ),
      ),
    ),
  );
}
