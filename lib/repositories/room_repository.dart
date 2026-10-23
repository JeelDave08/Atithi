import '../models/room.dart';
import '../services/room_service.dart';

/// The shared published-room source used by both Home and the Rooms screen.
class RoomRepository {
  RoomRepository({RoomService? service}) : _service = service ?? RoomService();

  final RoomService _service;

  Future<List<Room>> fetchRooms() =>
      _service.fetchRooms(sort: 'Recommended', from: 0, to: 999);
}
