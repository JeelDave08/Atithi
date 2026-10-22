class Room {
  const Room({
    required this.id,
    this.propertyId,
    required this.roomName,
    this.roomType,
    this.description,
    this.pricePerNight,
    this.capacity,
    this.amenities = const [],
    this.imageUrls = const [],
    this.status,
    this.isPublished = true,
    this.createdAt,
    this.badge,
    this.bedInfo,
    this.sizeSqft,
    this.rating,
    this.sortOrder,
    this.unitsLeft,
  });

  final String id;
  final String? propertyId;
  final String? roomName;
  final String? roomType;
  final String? description;
  final double? pricePerNight;
  final int? capacity;
  final List<String> amenities;
  final List<String> imageUrls;
  final String? status;
  final bool isPublished;
  final DateTime? createdAt;
  final String? badge;
  final String? bedInfo;
  final int? sizeSqft;
  final double? rating;
  final int? sortOrder;
  final int? unitsLeft;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id']?.toString() ?? '',
    propertyId: json['property_id']?.toString(),
    roomName: json['room_name']?.toString() ?? 'Room',
    roomType: json['room_type']?.toString(),
    description: json['description']?.toString(),
    pricePerNight: _toDouble(json['price_per_night']),
    capacity: _toInt(json['capacity']),
    amenities: _stringList(json['amenities']),
    imageUrls: _stringList(json['image_urls']),
    status: json['status']?.toString(),
    isPublished: json['is_published'] is bool
        ? json['is_published'] as bool
        : true,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.tryParse(json['created_at'].toString()),
    badge: json['badge']?.toString(),
    bedInfo: json['bed_info']?.toString(),
    sizeSqft: _toInt(json['size_sqft']),
    rating: _toDouble(json['rating']),
    sortOrder: _toInt(json['sort_order']),
    unitsLeft: _toInt(json['units_left']),
  );

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    return num.tryParse(value.toString())?.toDouble();
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    return num.tryParse(value.toString())?.toInt();
  }

  static List<String> _stringList(Object? value) =>
      value is Iterable ? value.whereType<String>().toList() : const [];
}
