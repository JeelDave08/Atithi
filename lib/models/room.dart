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
    id: json['id'] as String,
    propertyId: json['property_id'] as String?,
    roomName: json['room_name'] as String? ?? 'Room',
    roomType: json['room_type'] as String?,
    description: json['description'] as String?,
    pricePerNight: _toDouble(json['price_per_night']),
    capacity: _toInt(json['capacity']),
    amenities: List<String>.from(json['amenities'] as List? ?? const []),
    imageUrls: List<String>.from(json['image_urls'] as List? ?? const []),
    status: json['status'] as String?,
    isPublished: json['is_published'] as bool? ?? true,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.tryParse(json['created_at'].toString()),
    badge: json['badge'] as String?,
    bedInfo: json['bed_info'] as String?,
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
}
