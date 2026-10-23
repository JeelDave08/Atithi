import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import 'room_description.dart';

class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.unitsLeft,
    required this.available,
    required this.checking,
    required this.maxGuests,
    required this.onRetry,
    this.errorMessage,
    required this.compact,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onAdultsChange,
    required this.onChildrenChange,
    super.key,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final int? unitsLeft;
  final bool available;
  final bool checking;
  final int maxGuests;
  final String? errorMessage;
  final VoidCallback onRetry;
  final bool compact;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final ValueChanged<int> onAdultsChange;
  final ValueChanged<int> onChildrenChange;

  @override
  Widget build(BuildContext context) {
    final statusColor = errorMessage != null
        ? AppColors.greyText
        : available
        ? const Color(0xFF25804B)
        : const Color(0xFFB53838);
    final status = checking
        ? 'Checking availability'
        : errorMessage != null
        ? 'Availability check failed'
        : available
        ? 'Available'
        : 'Not available for selected dates';

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
          const SectionTitle('Your Stay'),
          const SizedBox(height: 12),
          if (compact) ...[
            _DateTile(label: 'Check In', date: checkIn, onTap: onCheckIn),
            const SizedBox(height: 9),
            _DateTile(label: 'Check Out', date: checkOut, onTap: onCheckOut),
          ] else
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Check In',
                    date: checkIn,
                    onTap: onCheckIn,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTile(
                    label: 'Check Out',
                    date: checkOut,
                    onTap: onCheckOut,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          if (compact) ...[
            _GuestStepper(
              label: 'Adults',
              count: adults,
              minimum: 1,
              canIncrease: adults + children < maxGuests,
              onChanged: onAdultsChange,
            ),
            const SizedBox(height: 4),
            _GuestStepper(
              label: 'Children',
              count: children,
              minimum: 0,
              canIncrease: adults + children < maxGuests,
              onChanged: onChildrenChange,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _GuestStepper(
                    label: 'Adults',
                    count: adults,
                    minimum: 1,
                    canIncrease: adults + children < maxGuests,
                    onChanged: onAdultsChange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GuestStepper(
                    label: 'Children',
                    count: children,
                    minimum: 0,
                    canIncrease: adults + children < maxGuests,
                    onChanged: onChildrenChange,
                  ),
                ),
              ],
            ),
          const Divider(height: 22, color: AppColors.border),
          Row(
            children: [
              if (checking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  !available ? Icons.info_outline : Icons.check_circle_outline,
                  color: statusColor,
                  size: 19,
                ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: checking ? AppColors.navy : statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$nights ${nights == 1 ? 'Night' : 'Nights'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 11,
                    ),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ],
          if (adults + children > maxGuests) ...[
            const SizedBox(height: 5),
            Text(
              'Max $maxGuests guests',
              style: const TextStyle(color: AppColors.greyText, fontSize: 11),
            ),
          ],
          if (available && unitsLeft != null && unitsLeft! <= 2) ...[
            const SizedBox(height: 7),
            Text(
              'Only $unitsLeft left',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (unitsLeft != null) ...[
            const SizedBox(height: 5),
            Text(
              '$unitsLeft Rooms Left',
              style: const TextStyle(color: AppColors.greyText, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cream,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.greyText, fontSize: 11),
            ),
            const SizedBox(height: 3),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 7,
              children: [
                Text(
                  DateFormat('d').format(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    DateFormat('MMM yyyy').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              DateFormat('EEEE').format(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.greyText, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuestStepper extends StatelessWidget {
  const _GuestStepper({
    required this.label,
    required this.count,
    required this.minimum,
    required this.canIncrease,
    required this.onChanged,
  });

  final String label;
  final int count;
  final int minimum;
  final bool canIncrease;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '$label · $count',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: count > minimum ? () => onChanged(-1) : null,
        icon: const Icon(Icons.remove_circle_outline, color: AppColors.navy),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: canIncrease ? () => onChanged(1) : null,
        icon: const Icon(Icons.add_circle_outline, color: AppColors.darkGold),
      ),
    ],
  );
}
