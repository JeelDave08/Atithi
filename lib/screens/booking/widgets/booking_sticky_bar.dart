import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';

class BookingStickyBar extends StatelessWidget {
  const BookingStickyBar({
    required this.total,
    required this.enabled,
    required this.submitting,
    required this.onConfirm,
    super.key,
  });

  final double total;
  final bool enabled;
  final bool submitting;
  final VoidCallback onConfirm;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Amount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.greyText, fontSize: 11),
              ),
              Text(
                _currency.format(total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: enabled && !submitting ? onConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.cream,
              disabledBackgroundColor: AppColors.greyText,
              minimumSize: const Size(0, 52),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 17),
            ),
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cream,
                    ),
                  )
                : const Icon(Icons.lock_outline, size: 18),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Confirm Booking', maxLines: 1, softWrap: false),
            ),
          );
          return constraints.maxWidth < 390
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [totalWidget, const SizedBox(height: 8), button],
                )
              : Row(
                  children: [
                    Expanded(child: totalWidget),
                    const SizedBox(width: 10),
                    button,
                  ],
                );
        },
      ),
    ),
  );
}
