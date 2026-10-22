import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'room_description.dart';

class RoomAmenitiesCard extends StatelessWidget {
  const RoomAmenitiesCard({required this.amenities, super.key});

  final List<String> amenities;

  static const _labels = <String, String>{
    'wifi': 'Wi-Fi',
    'tv': 'TV',
    'ac': 'AC',
    'mini_bar': 'Mini Bar',
    'room_service': 'Room Service',
    'work_desk': 'Work Desk',
    'balcony': 'Balcony',
    'kids_friendly': 'Kids Friendly',
  };

  static const _icons = <String, IconData>{
    'wifi': Icons.wifi_outlined,
    'tv': Icons.tv_outlined,
    'ac': Icons.ac_unit,
    'mini_bar': Icons.local_bar,
    'room_service': Icons.room_service,
    'work_desk': Icons.desk,
    'balcony': Icons.window_outlined,
    'kids_friendly': Icons.child_friendly,
  };

  @override
  Widget build(BuildContext context) {
    final values = amenities.toSet().toList();
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
          Row(
            children: [
              const Expanded(child: SectionTitle('Amenities')),
              if (values.isNotEmpty)
                TextButton(
                  onPressed: () => _showAll(context, values),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkGold,
                  ),
                  child: const Text('View all'),
                ),
            ],
          ),
          Container(
            width: 42,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          if (values.isEmpty)
            const Text(
              'No amenities listed yet.',
              style: TextStyle(color: AppColors.greyText, fontSize: 13),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: values
                    .map(
                      (key) => Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: _AmenityItem(keyName: key),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showAll(BuildContext context, List<String> values) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: SectionTitle('All Amenities')),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.navy),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: values
                    .map((key) => _AmenityItem(keyName: key))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String labelFor(String key) {
    final label = _labels[key];
    if (label != null) return label;
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _AmenityItem extends StatelessWidget {
  const _AmenityItem({required this.keyName});

  final String keyName;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.cream,
          child: Icon(
            RoomAmenitiesCard._icons[keyName] ?? Icons.check,
            color: AppColors.darkGold,
            size: 21,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          RoomAmenitiesCard.labelFor(keyName),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.navy, fontSize: 10),
        ),
      ],
    ),
  );
}
