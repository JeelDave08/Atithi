import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/wishlist_button.dart';

class RoomDetailsHeader extends StatelessWidget {
  const RoomDetailsHeader({
    required this.roomId,
    required this.onBack,
    required this.onShare,
    super.key,
  });

  final String roomId;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          // 1. Back Button
          _CircleButton(
            icon: Icons.chevron_left_rounded,
            iconSize: 26,
            onPressed: onBack,
          ),

          const Spacer(),

          // 2. Centered Atithi Logo Mark
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFEFE8DB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/atithi_mark.png',
              fit: BoxFit.contain,
            ),
          ),

          const Spacer(),

          // 3. Favourite Heart Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: WishlistButton(
              roomId: roomId,
              size: 40,
            ),
          ),

          const SizedBox(width: 8),

          // 4. Share Button
          _CircleButton(
            icon: Icons.share_outlined,
            iconSize: 19,
            onPressed: onShare,
          ),
        ],
      ),
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onPressed,
    this.iconSize = 20,
  });

  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 1,
    shadowColor: const Color(0x18000000),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEFE8DB), width: 1),
        ),
        child: Center(
          child: Icon(
            icon,
            color: AppColors.navy,
            size: iconSize,
          ),
        ),
      ),
    ),
  );
}
