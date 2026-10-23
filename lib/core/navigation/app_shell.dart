import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../responsive/app_container.dart';
import '../responsive/breakpoints.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.body,
    required this.activeRoute,
    this.backgroundColor = AppColors.cream,
    this.wrapInContainer = true,
    super.key,
  });

  final Widget body;
  final String activeRoute;
  final Color backgroundColor;
  final bool wrapInContainer;

  static const _destinations = <(String, String, IconData)>[
    ('Home', '/home', Icons.home_outlined),
    ('Rooms', '/rooms', Icons.bed_outlined),
    ('Bookings', '/bookings', Icons.calendar_month_outlined),
    ('About', '/about', Icons.info_outline_rounded),
    ('Contact', '/contact', Icons.call_outlined),
    ('Profile', '/profile', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final content = wrapInContainer
        ? AppContainer(backgroundColor: backgroundColor, child: body)
        : body;
    final desktop = context.screenWidth >= 600;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          if (desktop) _DesktopNavigation(activeRoute: activeRoute),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: desktop
          ? null
          : _MobileNavigation(activeRoute: activeRoute),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({required this.activeRoute});
  final String activeRoute;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.navy,
    child: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              return SizedBox(
                height: 72,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 28),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/home'),
                        child: SizedBox(
                          height: 48,
                          child: Center(
                            child: Text(
                              'ATITHI',
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.gold,
                                fontSize: compact ? 20 : 25,
                                letterSpacing: compact ? 1.6 : 2.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      for (final destination in AppShell._destinations)
                        _NavLink(
                          label: destination.$1,
                          route: destination.$2,
                          icon: destination.$3,
                          selected: activeRoute == destination.$2,
                          showIcon: !compact,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.route,
    required this.icon,
    required this.selected,
    required this.showIcon,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool selected;
  final bool showIcon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => context.go(route),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcon) ...[
                      Icon(icon, size: 17, color: AppColors.cream),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  width: selected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.activeRoute});
  final String activeRoute;

  static const _items = <(String, String, IconData)>[
    ('Home', '/home', Icons.home_outlined),
    ('Rooms', '/rooms', Icons.bed_outlined),
    ('Bookings', '/bookings', Icons.calendar_month_outlined),
    ('Profile', '/profile', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 66,
        child: Row(
          children: [
            for (final item in _items)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: activeRoute == item.$2,
                  label: item.$1,
                  child: InkWell(
                    onTap: () => context.go(item.$2),
                    child: SizedBox(
                      height: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.$3, size: 22, color: AppColors.navy),
                          const SizedBox(height: 2),
                          Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.navy,
                              fontWeight: activeRoute == item.$2
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
