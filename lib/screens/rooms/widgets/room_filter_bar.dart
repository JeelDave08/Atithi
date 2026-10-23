import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _filterCream = Color(0xFFFAF3E4);
const _filterNavy = Color(0xFF12284C);
const _filterGold = Color(0xFFD4A84F);
const _filterMuted = Color(0xFF777973);

class RoomFilters {
  RoomFilters({
    Set<String> priceRanges = const {},
    Set<String> roomTypes = const {},
    Set<String> capacities = const {},
    Set<String> amenities = const {},
  }) : priceRanges = Set.unmodifiable(priceRanges),
       roomTypes = Set.unmodifiable(roomTypes),
       capacities = Set.unmodifiable(capacities),
       amenities = Set.unmodifiable(amenities);

  final Set<String> priceRanges;
  final Set<String> roomTypes;
  final Set<String> capacities;
  final Set<String> amenities;

  static RoomFilters empty() => RoomFilters();

  bool get isEmpty =>
      priceRanges.isEmpty &&
      roomTypes.isEmpty &&
      capacities.isEmpty &&
      amenities.isEmpty;

  int get activeCount =>
      priceRanges.length +
      roomTypes.length +
      capacities.length +
      amenities.length;

  RoomFilters copyWith({
    Set<String>? priceRanges,
    Set<String>? roomTypes,
    Set<String>? capacities,
    Set<String>? amenities,
  }) => RoomFilters(
    priceRanges: priceRanges ?? this.priceRanges,
    roomTypes: roomTypes ?? this.roomTypes,
    capacities: capacities ?? this.capacities,
    amenities: amenities ?? this.amenities,
  );

  static String roomTypeKey(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\b(room|suite)\b'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  static List<String> uniqueRoomTypes(Iterable<String> values) {
    final unique = <String, String>{};
    for (final value in values) {
      final display = _titleCase(value.trim());
      final key = roomTypeKey(display);
      if (key.isEmpty) continue;
      final current = unique[key];
      if (current == null || _typeRank(display) < _typeRank(current)) {
        unique[key] = display;
      }
    }
    return unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  static int _typeRank(String value) {
    final hasSuffix = RegExp(
      r'\b(room|suite)\b',
      caseSensitive: false,
    ).hasMatch(value);
    return hasSuffix ? 1 : 0;
  }

  static String _titleCase(String value) => value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

class RoomFilterBar extends StatelessWidget {
  const RoomFilterBar({
    required this.categories,
    required this.category,
    required this.filters,
    required this.onCategory,
    required this.onApply,
    required this.resultCount,
    super.key,
  });

  final List<String> categories;
  final String category;
  final RoomFilters filters;
  final ValueChanged<String> onCategory;
  final ValueChanged<RoomFilters> onApply;
  final int Function(RoomFilters) resultCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
    decoration: BoxDecoration(
      color: _filterCream,
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
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _categoryChip('All', Icons.grid_view_rounded),
                    ...categories
                        .where((value) => value != 'All')
                        .map(
                          (value) => _categoryChip(value, Icons.bed_outlined),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => _openFilters(context),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Filters', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _filterNavy,
                side: const BorderSide(color: _filterGold),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _summaryPill(context, 'Price', _summarize(filters.priceRanges)),
              _summaryPill(context, 'Type', _summarize(filters.roomTypes)),
              _summaryPill(context, 'Guests', _summarize(filters.capacities)),
              _summaryPill(
                context,
                'Amenities',
                filters.amenities.isEmpty
                    ? 'Any'
                    : '${filters.amenities.length} selected',
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _categoryChip(String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: category == label ? Colors.white : _filterNavy,
        ),
      ),
      avatar: Icon(
        icon,
        size: 14,
        color: category == label ? Colors.white : _filterGold,
      ),
      selected: category == label,
      onSelected: (_) => onCategory(label),
      selectedColor: _filterNavy,
      backgroundColor: _filterCream,
      side: BorderSide(
        color: category == label
            ? _filterNavy
            : _filterGold.withValues(alpha: .65),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 7),
    ),
  );

  Widget _summaryPill(BuildContext context, String title, String value) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: Colors.white,
          shape: StadiumBorder(
            side: BorderSide(color: _filterGold.withValues(alpha: .55)),
          ),
          child: InkWell(
            onTap: () => _openFilters(context),
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 10, color: _filterMuted),
                    ),
                    if (value != 'Any') ...[
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 95),
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _filterNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 15,
                      color: _filterNavy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  String _summarize(Set<String> values) {
    if (values.isEmpty) return 'Any';
    if (values.length == 1) return values.first;
    return '${values.length} selected';
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await showModalBottomSheet<RoomFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: .85,
        maxChildSize: .95,
        minChildSize: .5,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: FilterBottomSheet(
            categories: categories,
            initialFilters: filters,
            scrollController: scrollController,
            resultCount: resultCount,
            onClear: onApply,
          ),
        ),
      ),
    );
    if (result != null) onApply(result);
  }
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    required this.categories,
    required this.initialFilters,
    required this.scrollController,
    required this.resultCount,
    required this.onClear,
    super.key,
  });

  final List<String> categories;
  final RoomFilters initialFilters;
  final ScrollController scrollController;
  final int Function(RoomFilters) resultCount;
  final ValueChanged<RoomFilters> onClear;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RoomFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
  }

  void _toggle(
    Set<String> source,
    String value,
    void Function(Set<String>) set,
  ) {
    final updated = {...source};
    if (!updated.add(value)) updated.remove(value);
    setState(() => set(updated));
  }

  void _clear() {
    setState(() => _filters = RoomFilters.empty());
    widget.onClear(RoomFilters.empty());
  }

  void _showResults() => Navigator.of(context).pop(_filters);

  @override
  Widget build(BuildContext context) {
    final count = widget.resultCount(_filters);
    return Container(
      color: _filterCream,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FilterSheetHeader(
              activeCount: _filters.activeCount,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilterSection(
                      title: 'Price Range',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _priceRanges
                            .map(
                              (value) => FilterChipItem(
                                label: value,
                                selected: _filters.priceRanges.contains(value),
                                onTap: () => _toggle(
                                  _filters.priceRanges,
                                  value,
                                  (values) => _filters = _filters.copyWith(
                                    priceRanges: values,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    FilterSection(
                      title: 'Room Type',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.categories
                            .map(
                              (value) => FilterChipItem(
                                label: value,
                                selected: _filters.roomTypes.contains(value),
                                onTap: () => _toggle(
                                  _filters.roomTypes,
                                  value,
                                  (values) => _filters = _filters.copyWith(
                                    roomTypes: values,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    FilterSection(
                      title: 'Capacity',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _capacities
                            .map(
                              (value) => FilterChipItem(
                                label: value,
                                selected: _filters.capacities.contains(value),
                                onTap: () => _toggle(
                                  _filters.capacities,
                                  value,
                                  (values) => _filters = _filters.copyWith(
                                    capacities: values,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    FilterSection(
                      title: 'Amenities',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _amenityValues
                            .map(
                              (value) => FilterChipItem(
                                label: _amenityLabels[value] ?? value,
                                icon: _amenityIcons[value],
                                selected: _filters.amenities.contains(value),
                                onTap: () => _toggle(
                                  _filters.amenities,
                                  value,
                                  (values) => _filters = _filters.copyWith(
                                    amenities: values,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilterBottomBar(
              filters: _filters,
              resultCount: count,
              onClear: _clear,
              onApply: _showResults,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetHeader extends StatelessWidget {
  const _FilterSheetHeader({required this.activeCount, required this.onClose});

  final int activeCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
    child: Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _filterMuted.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Filters',
                style: GoogleFonts.playfairDisplay(
                  color: _filterNavy,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (activeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _filterGold.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$activeCount ${activeCount == 1 ? 'filter' : 'filters'}',
                  style: const TextStyle(
                    color: _filterNavy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            IconButton(
              onPressed: onClose,
              tooltip: 'Close filters',
              icon: const Icon(Icons.close_rounded, color: _filterNavy),
            ),
          ],
        ),
      ],
    ),
  );
}

class FilterSection extends StatelessWidget {
  const FilterSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: _filterNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        child,
        const SizedBox(height: 18),
        Divider(height: 1, color: _filterGold.withValues(alpha: .35)),
      ],
    ),
  );
}

class FilterChipItem extends StatelessWidget {
  const FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _filterNavy : _filterCream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _filterNavy : _filterGold,
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                const Icon(Icons.check_rounded, size: 16, color: _filterGold)
              else if (icon != null)
                Icon(icon, size: 16, color: _filterGold),
              if (selected || icon != null) const SizedBox(width: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _filterNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FilterBottomBar extends StatelessWidget {
  const FilterBottomBar({
    required this.filters,
    required this.resultCount,
    required this.onClear,
    required this.onApply,
    super.key,
  });

  final RoomFilters filters;
  final int resultCount;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: _filterCream,
        border: Border(
          top: BorderSide(color: _filterGold.withValues(alpha: .3)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: filters.isEmpty ? null : onClear,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear all', maxLines: 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: filters.isEmpty ? _filterMuted : _filterNavy,
                side: BorderSide(
                  color: filters.isEmpty
                      ? _filterMuted.withValues(alpha: .4)
                      : _filterNavy,
                ),
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: _filterNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Show $resultCount rooms', maxLines: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _priceRanges = ['Under 4000', '4000-6000', '6000+'];
const _capacities = ['1-2', '3-4', '5+'];
const _amenityValues = [
  'wifi',
  'tv',
  'ac',
  'room_service',
  'mini_bar',
  'kids_friendly',
  'work_desk',
];
const _amenityLabels = {
  'wifi': 'Wi-Fi',
  'tv': 'TV',
  'ac': 'AC',
  'room_service': 'Room Service',
  'mini_bar': 'Mini Bar',
  'kids_friendly': 'Kids Friendly',
  'work_desk': 'Work Desk',
};
const _amenityIcons = {
  'wifi': Icons.wifi_rounded,
  'tv': Icons.tv_rounded,
  'ac': Icons.ac_unit_rounded,
  'room_service': Icons.room_service_rounded,
  'mini_bar': Icons.local_bar_rounded,
  'kids_friendly': Icons.child_friendly_rounded,
  'work_desk': Icons.desk_rounded,
};
