import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';

class RoomService {
  RoomService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Room>> fetchRooms({
    String? roomType,
    String? priceRange,
    String? capacityRange,
    Set<String> amenities = const {},
    String sort = 'Recommended',
  }) async {
    var query = _client.from('rooms').select().eq('is_published', true);

    if (roomType != null && roomType != 'All') {
      query = query.eq('room_type', roomType);
    }
    if (priceRange == 'Under 4000') {
      query = query.lt('price_per_night', 4000);
    } else if (priceRange == '4000-6000') {
      query = query.gte('price_per_night', 4000).lte('price_per_night', 6000);
    } else if (priceRange == '6000+') {
      query = query.gt('price_per_night', 6000);
    }

    if (capacityRange == '1-2') {
      query = query.gte('capacity', 1).lte('capacity', 2);
    } else if (capacityRange == '3-4') {
      query = query.gte('capacity', 3).lte('capacity', 4);
    } else if (capacityRange == '5+') {
      query = query.gte('capacity', 5);
    }

    if (amenities.isNotEmpty) {
      query = query.contains('amenities', amenities.toList());
    }

    // Keep the recommended database order for this screen.
    final rows = await query.order('sort_order', ascending: true);
    final rooms = <Room>[];
    for (final row in rows) {
      try {
        rooms.add(Room.fromJson(row));
      } catch (error, stack) {
        debugPrint('Skipping invalid room row: $row\n$error\n$stack');
      }
    }
    return rooms;
  }

  Future<int> debugRoomRowCount() async {
    final rows = await _client.from('rooms').select('id');
    return rows.length;
  }

  Future<List<String>> fetchCategories() async {
    final rows = await _client
        .from('rooms')
        .select('room_type')
        .eq('is_published', true);
    return rows
        .map((row) => row['room_type'])
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  Future<Set<String>> fetchFavoriteIds(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('room_id')
        .eq('user_id', userId);
    return rows.map((row) => row['room_id'] as String).toSet();
  }

  Future<void> toggleFavorite(
    String userId,
    String roomId, {
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('room_id', roomId);
    } else {
      await _client.from('favorites').insert({
        'user_id': userId,
        'room_id': roomId,
      });
    }
  }
}
