import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/room.dart';
import '../../../theme/app_colors.dart';
import '../../room_details/room_details_constants.dart';
import 'booking_section_card.dart';

class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    super.key,
  });

  final Room room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final nights = checkOut.difference(checkIn).inDays;
    final price = (room.pricePerNight ?? 0) * nights;
    final taxes = price * kTaxRate;
    return BookingSectionCard(
      title: 'Booking Summary',
      child: Column(
        children: [
          _line('Room Type', room.roomType ?? 'Room'),
          _line('Check-in', DateFormat('d MMM yyyy').format(checkIn)),
          _line('Check-out', DateFormat('d MMM yyyy').format(checkOut)),
          _line('No. of Nights', '$nights'),
          _line(
            'Guests',
            '$adults Adults + $children Child${children == 1 ? '' : 'ren'}',
          ),
          const Divider(height: 22, color: AppColors.border),
          _line('Room Price ($nights Nights)', _currency.format(price)),
          _line('Taxes & Fees (12%)', _currency.format(taxes)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: .20),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(
                  'Total Amount',
                  _currency.format(price + taxes),
                  bold: true,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.darkGold,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'You can cancel this booking up to 24 hours before check-in.',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.greyText,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
