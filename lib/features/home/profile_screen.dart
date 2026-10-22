import 'package:flutter/material.dart';

import '../../shared/widgets/sunset_widgets.dart';
import '../../theme/app_colors.dart';
import '../../widgets/logout_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.navy,
    body: SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: serif(32, italic: true)),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Color(0xFFD9534F),
                    ),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Color(0xFFD9534F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => showLogoutDialog(context),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: FloatingBottomNav(selected: 4),
          ),
        ],
      ),
    ),
  );
}
