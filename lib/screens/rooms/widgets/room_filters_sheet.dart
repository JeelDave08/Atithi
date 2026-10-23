import 'package:flutter/material.dart';

import '../../../models/room.dart';
import '../../../theme/app_colors.dart';
import '../models/room_filters.dart';

Future<RoomFilters?> showRoomFilters({
  required BuildContext context,
  required List<Room> rooms,
  required RoomFilters initial,
  required String searchQuery,
}) {
  final content = RoomFiltersSheet(
    rooms: rooms,
    initial: initial,
    searchQuery: searchQuery,
  );
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<RoomFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        minChildSize: .6,
        maxChildSize: .95,
        builder: (_, controller) => content.withController(controller),
      ),
    );
  }
  return showDialog<RoomFilters>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: content,
      ),
    ),
  );
}

class RoomFiltersSheet extends StatefulWidget {
  const RoomFiltersSheet({
    required this.rooms,
    required this.initial,
    required this.searchQuery,
    this.controller,
    super.key,
  });

  final List<Room> rooms;
  final RoomFilters initial;
  final String searchQuery;
  final ScrollController? controller;

  RoomFiltersSheet withController(ScrollController value) => RoomFiltersSheet(
    rooms: rooms,
    initial: initial,
    searchQuery: searchQuery,
    controller: value,
  );

  @override
  State<RoomFiltersSheet> createState() => _RoomFiltersSheetState();
}

class _RoomFiltersSheetState extends State<RoomFiltersSheet> {
  late RoomFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial.copyWith(
      types: {...widget.initial.types},
      amenities: {...widget.initial.amenities},
    );
  }

  double get _minPrice => widget.rooms
      .map((room) => room.pricePerNight ?? 0)
      .fold(double.infinity, (a, b) => a < b ? a : b);
  double get _maxPrice => widget.rooms
      .map((room) => room.pricePerNight ?? 0)
      .fold(0, (a, b) => a > b ? a : b);
  int get _maxGuests => widget.rooms
      .map((room) => room.capacity ?? 1)
      .fold(1, (a, b) => a > b ? a : b);

  int get _resultCount =>
      applyFilters(widget.rooms, _filters, widget.searchQuery).length;

  @override
  Widget build(BuildContext context) {
    final types =
        widget.rooms
            .map((room) => room.roomType?.trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final amenities =
        widget.rooms
            .expand((room) => room.amenities)
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final minPrice = _minPrice.isFinite ? _minPrice : 0.0;
    final maxPrice = _maxPrice > minPrice ? _maxPrice : minPrice + 1;
    final selectedRange = _filters.price ?? RangeValues(minPrice, maxPrice);

    return Column(
      children: [
        if (MediaQuery.sizeOf(context).width < 600)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.navy),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _section(
                'Room Type / Category',
                Wrap(
                  spacing: 8,
                  children: types
                      .map(
                        (type) =>
                            _chip(type, _filters.types.contains(type), () {
                              final next = {..._filters.types};
                              next.contains(type)
                                  ? next.remove(type)
                                  : next.add(type);
                              setState(
                                () => _filters = _filters.copyWith(types: next),
                              );
                            }),
                      )
                      .toList(),
                ),
              ),
              _section(
                'Price Range',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${selectedRange.start.round()} - ₹${selectedRange.end.round()}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RangeSlider(
                      values: selectedRange,
                      min: minPrice,
                      max: maxPrice,
                      divisions: maxPrice - minPrice > 1 ? 100 : null,
                      activeColor: AppColors.gold,
                      labels: RangeLabels(
                        '₹${selectedRange.start.round()}',
                        '₹${selectedRange.end.round()}',
                      ),
                      onChanged: (value) => setState(
                        () => _filters = _filters.copyWith(price: value),
                      ),
                    ),
                  ],
                ),
              ),
              _section(
                'Guests',
                Row(
                  children: [
                    IconButton(
                      onPressed: (_filters.guests ?? 1) <= 1
                          ? null
                          : () => setState(
                              () => _filters = _filters.copyWith(
                                guests: (_filters.guests ?? 1) - 1,
                              ),
                            ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${_filters.guests ?? 1} guests',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: (_filters.guests ?? 1) >= _maxGuests
                          ? null
                          : () => setState(
                              () => _filters = _filters.copyWith(
                                guests: (_filters.guests ?? 1) + 1,
                              ),
                            ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    TextButton(
                      onPressed: () => setState(
                        () => _filters = _filters.copyWith(clearGuests: true),
                      ),
                      child: const Text('Any'),
                    ),
                  ],
                ),
              ),
              _section(
                'Amenities',
                Wrap(
                  spacing: 8,
                  children: amenities
                      .map(
                        (item) => _chip(
                          item,
                          _filters.amenities.contains(item),
                          () {
                            final next = {..._filters.amenities};
                            next.contains(item)
                                ? next.remove(item)
                                : next.add(item);
                            setState(
                              () =>
                                  _filters = _filters.copyWith(amenities: next),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              _section(
                'Sort by',
                Wrap(
                  spacing: 8,
                  children: SortOption.values
                      .map(
                        (sort) => _chip(
                          _sortLabel(sort),
                          _filters.sort == sort,
                          () => setState(
                            () => _filters = _filters.copyWith(sort: sort),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _filters = _filters.clear()),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, _filters),
                    child: Text('Show $_resultCount rooms'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) => FilterChip(
    label: Text(label, overflow: TextOverflow.ellipsis),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.navy,
    checkmarkColor: Colors.white,
    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.navy),
    side: const BorderSide(color: AppColors.gold),
  );

  String _sortLabel(SortOption value) => switch (value) {
    SortOption.recommended => 'Recommended',
    SortOption.priceLowHigh => 'Price low-high',
    SortOption.priceHighLow => 'Price high-low',
    SortOption.rating => 'Rating',
  };
}

List<Room> applyFilters(
  List<Room> rooms,
  RoomFilters filters,
  String searchQuery,
) {
  final words = searchQuery
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .map((word) => word.replaceAll(RegExp(r'[-\s]'), ''))
      .where((word) => word.isNotEmpty)
      .toList();
  final result = rooms.where((room) {
    if (filters.types.isNotEmpty && !filters.types.contains(room.roomType)) {
      return false;
    }
    final price = room.pricePerNight ?? 0;
    if (filters.price != null &&
        (price < filters.price!.start || price > filters.price!.end)) {
      return false;
    }
    if (filters.guests != null && (room.capacity ?? 0) < filters.guests!) {
      return false;
    }
    if (!filters.amenities.every(room.amenities.contains)) return false;
    final haystack =
        [
              room.roomNumber,
              room.roomName,
              room.roomType,
              room.description,
              ...room.amenities,
              room.bedInfo,
              '${room.capacity ?? ''} guests',
              '${room.pricePerNight?.round() ?? ''}',
            ]
            .whereType<String>()
            .join(' ')
            .toLowerCase()
            .replaceAll(RegExp(r'[-\s]'), '');
    return words.every(haystack.contains);
  }).toList();
  switch (filters.sort) {
    case SortOption.recommended:
      break;
    case SortOption.priceLowHigh:
      result.sort(
        (a, b) => (a.pricePerNight ?? 0).compareTo(b.pricePerNight ?? 0),
      );
    case SortOption.priceHighLow:
      result.sort(
        (a, b) => (b.pricePerNight ?? 0).compareTo(a.pricePerNight ?? 0),
      );
    case SortOption.rating:
      result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
  }
  return result;
}
