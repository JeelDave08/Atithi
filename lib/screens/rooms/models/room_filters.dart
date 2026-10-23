import 'package:flutter/material.dart';

enum SortOption { recommended, priceLowHigh, priceHighLow, rating }

class RoomFilters {
  const RoomFilters({
    this.types = const {},
    this.price,
    this.guests,
    this.amenities = const {},
    this.sort = SortOption.recommended,
  });

  final Set<String> types;
  final RangeValues? price;
  final int? guests;
  final Set<String> amenities;
  final SortOption sort;

  bool get isActive => activeCount > 0;
  int get activeCount =>
      types.length +
      (price == null ? 0 : 1) +
      (guests == null ? 0 : 1) +
      amenities.length +
      (sort == SortOption.recommended ? 0 : 1);

  RoomFilters copyWith({
    Set<String>? types,
    RangeValues? price,
    bool clearPrice = false,
    int? guests,
    bool clearGuests = false,
    Set<String>? amenities,
    SortOption? sort,
  }) => RoomFilters(
    types: types ?? this.types,
    price: clearPrice ? null : price ?? this.price,
    guests: clearGuests ? null : guests ?? this.guests,
    amenities: amenities ?? this.amenities,
    sort: sort ?? this.sort,
  );

  RoomFilters clear() => const RoomFilters();
}
