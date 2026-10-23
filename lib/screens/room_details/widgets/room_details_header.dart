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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
    child: ColoredBox(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              _CircleButton(icon: Icons.arrow_back, onPressed: onBack),
              const Spacer(),
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Image.asset(
                  'assets/images/atithi_mark.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              WishlistButton(roomId: roomId, size: 40, onDarkBackground: true),
              const SizedBox(width: 8),
              _CircleButton(icon: Icons.share_outlined, onPressed: onShare),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cream.withValues(alpha: .12),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
    ),
  );
}
