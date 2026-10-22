import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../room_details_constants.dart';
import 'room_description.dart';

class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    required this.pricePerNight,
    required this.nights,
    super.key,
  });

  final double pricePerNight;
  final int nights;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final roomTotal = pricePerNight * nights;
    final taxes = roomTotal * kTaxRate;
    final total = roomTotal + taxes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Price Breakdown'),
          const SizedBox(height: 14),
          _PriceRow(
            label: 'Room Price ($nights ${nights == 1 ? 'Night' : 'Nights'})',
            value: _currency.format(roomTotal),
          ),
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Taxes & Fees (12%)',
            value: _currency.format(taxes),
          ),
          const Divider(height: 24, color: AppColors.border),
          _PriceRow(
            label: 'Total Amount',
            value: _currency.format(total),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: bold ? AppColors.navy : AppColors.greyText,
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.navy,
          fontSize: bold ? 15 : 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}
