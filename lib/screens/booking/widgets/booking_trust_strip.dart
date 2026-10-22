import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class BookingTrustStrip extends StatelessWidget {
  const BookingTrustStrip({super.key});

  static const _items = [
    (Icons.lock_outline, 'Secure Payment'),
    (Icons.support_agent_outlined, '24/7 Support'),
    (Icons.sell_outlined, 'Best Rates'),
    (Icons.verified_user_outlined, 'Trusted by Millions'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 14,
    runSpacing: 10,
    children: _items
        .map(
          (item) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$1, color: AppColors.darkGold, size: 16),
              const SizedBox(width: 5),
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.greyText, fontSize: 10),
              ),
            ],
          ),
        )
        .toList(),
  );
}
