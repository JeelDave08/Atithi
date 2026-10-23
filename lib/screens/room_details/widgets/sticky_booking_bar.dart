import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';

class StickyBookingBar extends StatelessWidget {
  const StickyBookingBar({
    required this.total,
    required this.enabled,
    required this.onBook,
    super.key,
  });

  final double total;
  final bool enabled;
  final VoidCallback onBook;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 400;
        final totalLabel = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total Amount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.greyText, fontSize: 10),
            ),
            Text(
              '${_currency.format(total)} (Incl. taxes & fees)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

        final bookButtonColumn = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: enabled ? onBook : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.cream,
                  disabledBackgroundColor:
                      AppColors.navy.withValues(alpha: .35),
                  disabledForegroundColor: AppColors.cream,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: const StadiumBorder(),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Book This Room →',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Select check-in & check-out dates to continue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.greyText.withValues(alpha: .8),
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        );

        return Container(
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
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    totalLabel,
                    const SizedBox(height: 8),
                    bookButtonColumn,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: totalLabel),
                    const SizedBox(width: 10),
                    bookButtonColumn,
                  ],
                ),
        );
      },
    ),
  );
}
