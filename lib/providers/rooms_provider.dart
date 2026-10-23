import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room.dart';
import '../repositories/room_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => RoomRepository(),
);

/// Riverpod keeps one in-memory result shared between Home and Rooms.
final roomsProvider = FutureProvider<List<Room>>(
  (ref) => ref.watch(roomRepositoryProvider).fetchRooms(),
);
