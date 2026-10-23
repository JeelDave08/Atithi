import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoomFilterBar extends StatelessWidget {
  const RoomFilterBar({
    required this.categories,
    required this.category,
    required this.price,
    required this.type,
    required this.capacity,
    required this.amenities,
    required this.onCategory,
    required this.onFilter,
    required this.onClear,
    super.key,
  });
  final List<String> categories;
  final String category;
  final String? price, type, capacity;
  final Set<String> amenities;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onFilter;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final chips = [
              _category('All', Icons.grid_view),
              ...categories
                  .where((category) => category != 'All')
                  .map((category) => _category(category, Icons.bed_outlined)),
            ];
            final filterButton = OutlinedButton.icon(
              onPressed: () => _sheet(context, 'Filters'),
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Filters', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                minimumSize: const Size(48, 48),
              ),
            );
            if (constraints.maxWidth >= 700) {
              return Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [...chips, filterButton],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: chips),
                  ),
                ),
                const SizedBox(width: 6),
                filterButton,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final pills = [
              _pill(
                context,
                'Price Range',
                Icons.payments_outlined,
                price ?? 'Any',
              ),
              _pill(context, 'Room Type', Icons.bed_outlined, type ?? 'Any'),
              _pill(
                context,
                'Capacity',
                Icons.people_outline,
                capacity ?? 'Any',
              ),
              _pill(
                context,
                'Amenities',
                Icons.wifi,
                amenities.isEmpty ? 'Any' : '${amenities.length} selected',
              ),
            ];
            if (constraints.maxWidth >= 900) {
              return Wrap(spacing: 2, runSpacing: 6, children: pills);
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: pills),
            );
          },
        ),
      ],
    ),
  );
  Widget _category(String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: category == label ? Colors.white : AppColors.navy,
        ),
      ),
      avatar: Icon(
        icon,
        size: 14,
        color: category == label ? Colors.white : AppColors.darkGold,
      ),
      selected: category == label,
      onSelected: (_) => onCategory(label),
      selectedColor: AppColors.navy,
      backgroundColor: AppColors.cream,
      side: BorderSide(
        color: category == label
            ? AppColors.navy
            : AppColors.gold.withValues(alpha: .55),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 7),
    ),
  );
  Widget _pill(
    BuildContext context,
    String title,
    IconData icon,
    String value,
  ) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Material(
      color: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.gold.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: () => _sheet(context, title),
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.darkGold),
                const SizedBox(width: 5),
                Text(
                  _shortLabel(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.greyText,
                  ),
                ),
                if (value != 'Any') ...[
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 95),
                    child: Text(
                      _displayValue(value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 15,
                  color: AppColors.navy,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String _shortLabel(String title) => switch (title) {
    'Price Range' => 'Price',
    'Room Type' => 'Type',
    'Capacity' => 'Guests',
    _ => title,
  };

  String _displayValue(String value) => switch (value) {
    'Under 4000' => 'Under ₹4000',
    '4000-6000' => '₹4000–6000',
    '6000+' => '₹6000+',
    _ => value,
  };
  void _sheet(BuildContext context, String title) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (title == 'Filters') ...[
              _group(ctx, 'Price Range', ['Under 4000', '4000-6000', '6000+']),
              _group(ctx, 'Room Type', [...categories, 'Any']),
              _group(ctx, 'Capacity', ['1-2', '3-4', '5+']),
              _group(ctx, 'Amenities', [
                'wifi',
                'tv',
                'ac',
                'room_service',
                'mini_bar',
                'kids_friendly',
                'work_desk',
              ]),
            ] else
              _group(
                ctx,
                title,
                title == 'Price Range'
                    ? ['Under 4000', '4000-6000', '6000+']
                    : title == 'Capacity'
                    ? ['1-2', '3-4', '5+']
                    : title == 'Amenities'
                    ? [
                        'wifi',
                        'tv',
                        'ac',
                        'room_service',
                        'mini_bar',
                        'kids_friendly',
                        'work_desk',
                      ]
                    : [...categories, 'Any'],
              ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _group(BuildContext context, String title, List<String> values) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.greyText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Wrap(
              spacing: 7,
              runSpacing: 3,
              children: values
                  .map(
                    (v) => ActionChip(
                      label: Text(_label(v)),
                      onPressed: () {
                        onFilter('$title=$v');
                        if (title != 'Amenities' && title != 'Filters') {
                          Navigator.pop(context);
                        }
                      },
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.gold),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
  String _label(String value) => value == 'wifi'
      ? 'Wi-Fi'
      : value == 'tv'
      ? 'TV'
      : value == 'ac'
      ? 'AC'
      : value == 'room_service'
      ? 'Room Service'
      : value == 'mini_bar'
      ? 'Mini Bar'
      : value == 'kids_friendly'
      ? 'Kids Friendly'
      : value == 'work_desk'
      ? 'Work Desk'
      : value;
}
