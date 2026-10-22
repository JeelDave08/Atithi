import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'property_experience.dart';

const _cream = Color(0xFFFBF7EF);
const _cardCream = Color(0xFFFFFCF6);
const _navy = Color(0xFF102B46);
const _primaryNavy = Color(0xFF173A59);
const _gold = Color(0xFFC49A45);
const _lightGold = Color(0xFFE6C786);
const _mainText = Color(0xFF142C46);

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
              child: _HeroBanner(onTap: _openRoomListing),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
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
  Widget build(BuildContext context) => Padding(
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
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none_rounded, color: _navy),
        ),
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
  );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FutureBuilder<PropertyContent?>(
    future: const PropertyContentRepository().getActiveProperty(),
    builder: (context, snapshot) {
      final property = snapshot.data;
      final imageUrl = property?.imageUrls.isNotEmpty == true
          ? property!.imageUrls.first
          : null;
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 244,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const _HotelImageFallback(),
                  placeholder: (_, _) => const _HotelImageFallback(),
                )
              else
                const _HotelImageFallback(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xE6102B46), Color(0x00102B46)],
                    stops: [0, .9],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      property?.name.isNotEmpty == true
                          ? property!.name
                          : 'Welcome to Atithi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      property?.description.isNotEmpty == true
                          ? property!.description
                          : 'Discover a comfortable stay with Atithi.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: _lightGold,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onTap,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          child: Text(
                            'Find your stay',
                            style: TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
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
        Text(
          'Plan your stay',
          style: GoogleFonts.playfairDisplay(
            color: _mainText,
            fontSize: 21,
            fontWeight: FontWeight.w600,
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
              backgroundColor: _navy,
              foregroundColor: _lightGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.search_rounded),
            label: const Text(
              'Search Rooms',
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
                    MaterialLocalizations.of(context).formatMediumDate(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mainText,
                      fontSize: 12,
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
        Row(
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
        const SizedBox(height: 13),
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

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({required this.onTap});

  final ValueChanged<String> onTap;

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
            onTap: () => onTap(items[index].label),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cardCream,
                    border: Border.all(color: _lightGold, width: 1.2),
                  ),
                  child: Icon(items[index].icon, color: _navy, size: 24),
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
      color: _cardCream,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _lightGold.withValues(alpha: .5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'View property contact details or send a message to the team.',
          style: TextStyle(color: _mainText, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: _lightGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Get in Touch'),
          ),
        ),
      ],
    ),
  );
}

class _HomeBottomNavigation extends StatelessWidget {
  const _HomeBottomNavigation();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: _cardCream,
      boxShadow: [
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AtithiDestinationScreen(
                    title: 'My Bookings',
                    description: 'Your Atithi reservations will appear here when you have a booking.',
                  ),
                ),
              ),
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

class _HotelImageFallback extends StatelessWidget {
  const _HotelImageFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_primaryNavy, _navy],
      ),
    ),
    child: Center(
      child: Icon(Icons.hotel_rounded, color: _lightGold, size: 38),
    ),
  );
}
