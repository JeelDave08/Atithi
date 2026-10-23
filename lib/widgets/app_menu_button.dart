import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive/breakpoints.dart';
import '../theme/app_colors.dart';
import 'logout_dialog.dart';

/// Shared account and site navigation menu used by app headers.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({this.onDarkBackground = false, super.key});

  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final menuWidth = context.isMobile ? 240.0 : 260.0;
    return PopupMenuButton<String>(
      tooltip: 'Open menu',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 2),
      constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth),
      color: AppColors.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.gold.withValues(alpha: .3)),
      ),
      onSelected: (value) {
        switch (value) {
          case 'about':
            context.push('/about');
          case 'services':
            context.push('/services');
          case 'contact':
            context.push('/contact');
          case 'logout':
            showLogoutDialog(context);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'about',
          child: SizedBox(width: 200, child: Text('About Atithi')),
        ),
        const PopupMenuItem(
          value: 'services',
          child: SizedBox(width: 200, child: Text('Our Services')),
        ),
        const PopupMenuItem(
          value: 'contact',
          child: SizedBox(width: 200, child: Text('Contact Us')),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: SizedBox(
            width: 200,
            child: Row(
              children: [
                Icon(Icons.logout, color: AppColors.navy, size: 18),
                SizedBox(width: 8),
                Text('Log out'),
              ],
            ),
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: onDarkBackground
              ? Colors.white.withValues(alpha: .13)
              : Colors.transparent,
          shape: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: onDarkBackground
                  ? const Icon(Icons.menu, color: Colors.white, size: 22)
                  : const _HamburgerMark(),
            ),
          ),
        ),
      ),
    );
  }
}

class _HamburgerMark extends StatelessWidget {
  const _HamburgerMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24,
    height: 16,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        3,
        (_) => Container(
          height: 2.2,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ),
  );
}
