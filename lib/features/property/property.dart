class RoomType {
  const RoomType({
    required this.name,
    required this.guests,
    required this.beds,
    required this.price,
  });
  final String name, beds;
  final int guests, price;
}

class Property {
  const Property({
    required this.name,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.photos,
    required this.checkIn,
    required this.checkOut,
    required this.rooms,
    required this.type,
    required this.amenities,
    required this.description,
    required this.roomTypes,
  });
  final String name, location, checkIn, checkOut, type, description;
  final double rating;
  final int reviews, photos, rooms;
  final List<String> amenities;
  final List<RoomType> roomTypes;
}

abstract interface class PropertyRepository {
  Property get featured;
}

class MockPropertyRepository implements PropertyRepository {
  @override
  Property get featured => const Property(
    name: 'Sunset Villa Resort',
    location: 'Goa',
    rating: 4.8,
    reviews: 124,
    photos: 10,
    checkIn: '2:00 PM',
    checkOut: '11:00 AM',
    rooms: 24,
    type: 'Resort',
    amenities: ['WiFi', 'Pool', 'Dining', 'Parking', 'AC'],
    description: 'A serene coastal retreat where golden sunsets meet thoughtful hospitality. Unwind by the pool, savour local flavours, and make every evening one to remember.',
    roomTypes: [
      RoomType(name: 'Deluxe Room', guests: 2, beds: '1 King Bed', price: 4500),
      RoomType(
        name: 'Premium Room',
        guests: 3,
        beds: 'King Bed + Sofa',
        price: 6500,
      ),
      RoomType(
        name: 'Family Suite',
        guests: 4,
        beds: '2 King Beds',
        price: 9000,
      ),
    ],
  );
}
