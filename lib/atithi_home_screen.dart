import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'theme/app_colors.dart';
import 'features/home/widgets/reveal_on_scroll.dart';
import 'property_experience.dart';

const _cream = AppColors.cream;
const _cardCream = AppColors.cream;
const _navy = AppColors.navy;
const _primaryNavy = AppColors.navy;
const _gold = AppColors.gold;
const _lightGold = AppColors.gold;
const _mainText = AppColors.navy;

class AtithiHomeScreen extends StatefulWidget {
  const AtithiHomeScreen({super.key});

  @override
  State<AtithiHomeScreen> createState() => _AtithiHomeScreenState();
}

class _AtithiHomeScreenState extends State<AtithiHomeScreen> {
  final ScrollController _homeScrollController = ScrollController();
  late DateTime _checkIn = _dateOnly(DateTime.now());
  late DateTime _checkOut = _dateOnly(DateTime.now())
      .add(const Duration(days: 1));
  int _adults = 2;
  int _children = 0;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

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

  void _openDestination(String title, String description) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AtithiDestinationScreen(title: title, description: description),
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
        controller: _homeScrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHeader(
              onNotifications: () => _openDestination(
                'Notifications',
                'You are all caught up. New updates about your Atithi stays will appear here.',
              ),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _HeroBanner(
                onTap: _openRoomListing,
                scrollController: _homeScrollController,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: _BookingSearchCard(
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
    bottomNavigationBar: const _HomeBottomNavigation(),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onNotifications,
    required this.onMenuSelected,
  });

  final VoidCallback onNotifications;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) => RevealOnScroll(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
      child: Row(
        children: [
          SizedBox(
            width: 124,
            height: 48,
            child: Image.asset(
              'assets/images/atithi_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Text(
                'ATITHI',
                style: GoogleFonts.playfairDisplay(
                  color: _navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Spacer(),
          _PulsingBell(onPressed: onNotifications),
          PopupMenuButton<String>(
            tooltip: 'Open menu',
            onSelected: onMenuSelected,
            color: _cardCream,
            icon: const Icon(Icons.menu_rounded, color: _navy),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'About Atithi', child: Text('About Atithi')),
              PopupMenuItem(value: 'Our Services', child: Text('Our Services')),
              PopupMenuItem(value: 'Contact Us', child: Text('Contact Us')),
            ],
          ),
        ],
      ),
    ),
  );
}

// Flutter-only doorway scene keeps animation assets and backend logic unchanged.
class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.onTap, required this.scrollController});

  final VoidCallback onTap;
  final ScrollController scrollController;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _ambience = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat(reverse: true);
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat(reverse: true);
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced != _reducedMotion) {
      _reducedMotion = reduced;
      if (reduced) {
        _intro.value = 1;
        _ambience.stop();
        _glow.stop();
      } else {
        _intro.forward(from: 0);
        _ambience.repeat(reverse: true);
        _glow.repeat(reverse: true);
      }
    }
    if (!_intro.isAnimating && _intro.value == 0 && !reduced) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambience.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _replay() {
    if (_reducedMotion) return;
    _intro.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      _intro,
      _ambience,
      _glow,
      widget.scrollController,
    ]),
    builder: (context, _) {
      final scroll =
          !MediaQuery.disableAnimationsOf(context) &&
              widget.scrollController.hasClients
          ? widget.scrollController.offset
          : 0.0;
      final hour = DateTime.now().hour;
      final greeting = hour >= 5 && hour < 12
          ? 'Good Morning'
          : hour >= 17 && hour < 21
          ? 'Good Evening'
          : 'Good Night';
      final guestName = FirebaseAuth.instance.currentUser?.displayName
          ?.trim()
          .split(' ')
          .first;
      return ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: SizedBox(
          height: 440,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navy,
                      Color.lerp(_navy, _primaryNavy, _ambience.value)!,
                      _primaryNavy,
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, scroll * .08),
                child: _HeroStars(opacity: .38 + _ambience.value * .3),
              ),
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: const Size(170, 190),
                    painter: _DoorwayPainter(glow: _glow.value),
                  ),
                ),
              ),
              Positioned(
                right: (38 + (math.sin(_ambience.value * math.pi) * 18))
                    .toDouble(),
                top: (35 + (math.cos(_ambience.value * math.pi) * 8))
                    .toDouble(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cream,
                    boxShadow: [
                      BoxShadow(
                        color: _lightGold.withValues(alpha: .42),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, scroll * .2),
                  child: const _HeroSkyline(),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xD90B2347), Color(0x000B2347)],
                    stops: [0, .78],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 58, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guestName == null || guestName.isEmpty
                          ? '$greeting, Guest'
                          : 'Namaste, $guestName',
                      style: const TextStyle(
                        color: _lightGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Atithi Devo Bhava',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Where every guest is family.',
                      style: TextStyle(
                        color: _lightGold,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _RotatingHeroLine(),
                    const SizedBox(height: 14),
                    Material(
                      color: _lightGold,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: widget.onTap,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Find your stay',
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Transform.translate(
                                offset: Offset(_glow.value * 3, 0),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _navy,
                                  size: 16,
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
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _intro,
                    builder: (context, _) => Row(
                      children: [
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(
                              -MediaQuery.sizeOf(context).width *
                                  .5 *
                                  _intro.value,
                              0,
                            ),
                            child: const _HeroDoor(isLeft: true),
                          ),
                        ),
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(
                              MediaQuery.sizeOf(context).width *
                                  .5 *
                                  _intro.value,
                              0,
                            ),
                            child: const _HeroDoor(isLeft: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 8,
                child: IconButton(
                  onPressed: _replay,
                  tooltip: 'Tap to replay',
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  style: IconButton.styleFrom(foregroundColor: _lightGold),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HeroDoor extends StatelessWidget {
  const _HeroDoor({required this.isLeft});
  final bool isLeft;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        colors: const [_navy, _primaryNavy],
      ),
      border: Border.all(color: _lightGold.withValues(alpha: .5), width: 1.2),
    ),
    child: Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: _lightGold,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

class _DoorwayPainter extends CustomPainter {
  const _DoorwayPainter({required this.glow});
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final arch = Path()
      ..moveTo(size.width * .18, size.height)
      ..lineTo(size.width * .18, size.height * .45)
      ..cubicTo(
        size.width * .18,
        size.height * .06,
        size.width * .82,
        size.height * .06,
        size.width * .82,
        size.height * .45,
      )
      ..lineTo(size.width * .82, size.height)
      ..close();
    final haze = Paint()
      ..color = _gold.withValues(alpha: .11 + glow * .12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + glow * 10);
    canvas.drawPath(arch, haze);
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_gold, _gold, _navy],
      ).createShader(Offset.zero & size);
    canvas.drawPath(arch, fill);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _gold.withValues(alpha: .75 + glow * .25);
    canvas.drawPath(arch, frame);
    final seam = Paint()
      ..color = _navy.withValues(alpha: .45)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .5, size.height * .48),
      Offset(size.width * .5, size.height),
      seam,
    );
  }

  @override
  bool shouldRepaint(covariant _DoorwayPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

class _HeroStars extends StatelessWidget {
  const _HeroStars({required this.opacity});
  final double opacity;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: List.generate(50, (i) {
        final x = ((i * 47 + 13) % 97) / 100;
        final y = ((i * 31 + 9) % 48) / 100;
        return Positioned(
          left: MediaQuery.sizeOf(context).width * x,
          top: 440 * y,
          child: Opacity(
            opacity: opacity * (.55 + (i % 4) * .1),
            child: Icon(
              Icons.circle,
              size: i % 6 == 0 ? 3 : 2,
              color: _lightGold,
            ),
          ),
        );
      }),
    ),
  );
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

class _HeroSkyline extends StatelessWidget {
  const _HeroSkyline();
  static const List<double> _heights = [56, 88, 70, 108, 82, 62, 96, 58];
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: SizedBox(
      height: 125,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          _heights.length,
          (i) => Expanded(
            child: Container(
              height: _heights[i],
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: .9),
                border: i == 3
                    ? Border.all(
                        color: _gold.withValues(alpha: .75),
                        width: 1.3,
                      )
                    : null,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
              child: i == 3
                  ? Column(
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'ATITHI',
                          style: TextStyle(
                            color: _lightGold,
                            fontSize: 7,
                            letterSpacing: 1,
                            shadows: [Shadow(color: _gold, blurRadius: 8)],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 18,
                          height: 25,
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: .5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(5),
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: List.generate(
                          4,
                          (_) => Container(
                            width: 5,
                            height: 7,
                            color: _gold.withValues(alpha: .55),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RotatingHeroLine extends StatefulWidget {
  const _RotatingHeroLine();
  @override
  State<_RotatingHeroLine> createState() => _RotatingHeroLineState();
}

class _RotatingHeroLineState extends State<_RotatingHeroLine> {
  static const _words = [
    'comfortable rooms',
    'friendly service',
    'a relaxing stay',
    'warm hospitality',
  ];
  int _index = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        setState(() => _index = (_index + 1) % _words.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 350),
    transitionBuilder: (child, animation) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, .25),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    ),
    child: Text(
      'Enjoy ${_words[_index]}',
      key: ValueKey(_index),
      style: const TextStyle(
        color: _lightGold,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    ),
  );
}

class _BookingSearchCard extends StatelessWidget {
  const _BookingSearchCard({
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _cardCream,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _gold.withValues(alpha: .32)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x140F2943),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KEY CARD',
                      style: TextStyle(
                        color: _lightGold,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Plan your stay',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.nfc_rounded, color: _lightGold, size: 27),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DateChoice(
                label: 'Check-in',
                date: checkIn,
                onTap: onCheckInTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateChoice(
                label: 'Check-out',
                date: checkOut,
                onTap: onCheckOutTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GuestCounter(
                label: 'Adults',
                count: adults,
                icon: Icons.person_outline_rounded,
                onChanged: onAdultsChange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GuestCounter(
                label: 'Children',
                count: children,
                icon: Icons.child_care_outlined,
                onChanged: onChildrenChange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: onSearch,
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.search_rounded),
            label: const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DateChoice extends StatelessWidget {
  const _DateChoice({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _cream,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: _gold, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _primaryNavy, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEE, d MMM').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mainText,
                      fontSize: 14,
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

class _GuestCounter extends StatelessWidget {
  const _GuestCounter({
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: _cream,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: _gold, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _primaryNavy, fontSize: 11),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: _mainText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _CounterButton(
          icon: Icons.remove,
          onTap: () => onChanged(-1),
          tooltip: 'Decrease $label',
        ),
        const SizedBox(width: 4),
        _CounterButton(
          icon: Icons.add,
          onTap: () => onChanged(1),
          tooltip: 'Increase $label',
        ),
      ],
    ),
  );
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 27,
    height: 29,
    child: IconButton(
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: _navy),
      style: IconButton.styleFrom(
        backgroundColor: _lightGold.withValues(alpha: .35),
        minimumSize: const Size(27, 29),
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

class _PulsingBell extends StatefulWidget {
  const _PulsingBell({required this.onPressed});
  final VoidCallback onPressed;
  @override
  State<_PulsingBell> createState() => _PulsingBellState();
}

class _PulsingBellState extends State<_PulsingBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Notifications',
    onPressed: widget.onPressed,
    icon: AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.rotate(
            angle: math.sin(_pulse.value * math.pi * 2) * .08,
            child: const Icon(Icons.notifications_none_rounded, color: _navy),
          ),
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8 + _pulse.value * 2,
              height: 8 + _pulse.value * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold,
                border: Border.all(color: _cardCream, width: 1),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeBottomNavigation extends StatelessWidget {
  const _HomeBottomNavigation();

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
              icon: Icons.home_outlined,
              label: 'Home',
              selected: true,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.bed_outlined,
              label: 'Rooms',
              onTap: () => context.push('/rooms'),
            ),
            _NavItem(
              icon: Icons.event_note_outlined,
              label: 'Bookings',
              onTap: () => context.push('/bookings'),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () => context.push('/profile'),
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
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? _lightGold.withValues(alpha: .6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: _navy, size: 21),
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
