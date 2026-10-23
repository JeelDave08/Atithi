import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoomDetailsHeader extends StatelessWidget {
  const RoomDetailsHeader({
    required this.isFavorite,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
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
              _CircleButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                onPressed: onFavorite,
              ),
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
