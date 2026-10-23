import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';
import '../core/image_utils.dart';

class RoomService {
  RoomService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Room?> fetchRoomById(String roomId) async {
    final row = await _client
        .from('rooms')
        .select()
        .eq('id', roomId)
        .eq('is_published', true)
        .maybeSingle();
    if (row == null) return null;

    try {
      final room = Room.fromJson(row);
      _logRoomImages(room);
      return room;
    } catch (error, stack) {
      debugPrint('Could not parse room $roomId: $error\n$stack');
      rethrow;
    }
  }

  Future<bool> hasBookingConflict({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final rows = await _client
          .from('bookings')
          .select('id')
          .eq('room_id', roomId)
          .eq('booking_status', 'confirmed')
          .lt('check_in', _dateOnly(checkOut))
          .gt('check_out', _dateOnly(checkIn))
          .limit(1);
      return rows.isNotEmpty;
    } catch (error) {
      if (kDebugMode) debugPrint('Room availability check failed: $error');
      rethrow;
    }
  }

  Future<Set<String>> fetchBookedRoomIds({
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final start = _dateOnly(checkIn), end = _dateOnly(checkOut);
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      final rows = await _client
          .from('bookings')
          .select('room_id')
          .inFilter('booking_status', ['confirmed', 'pending'])
          .lt('check_in', end)
          .gt('check_out', start)
          .or(
            'booking_status.eq.confirmed,and(booking_status.eq.pending,expires_at.gt.$now)',
          );
      return rows.map((row) => row['room_id'].toString()).toSet();
    } catch (_) {
      final rows = await _client
          .from('bookings')
          .select('room_id')
          .eq('booking_status', 'confirmed')
          .lt('check_in', end)
          .gt('check_out', start);
      return rows.map((row) => row['room_id'].toString()).toSet();
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<List<Room>> fetchRooms({
    String? roomType,
    String? priceRange,
    String? capacityRange,
    Set<String> amenities = const {},
    String sort = 'Recommended',
    int from = 0,
    int to = 19,
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
    final rows = await query
        .order('sort_order', ascending: true)
        .range(from, to);
    final rooms = <Room>[];
    for (final row in rows) {
      try {
        final room = Room.fromJson(row);
        _logRoomImages(room);
        rooms.add(room);
      } catch (error, stack) {
        debugPrint('Skipping invalid room row: $row\n$error\n$stack');
      }
    }
    return rooms;
  }

  void _logRoomImages(Room room) {
    if (!kDebugMode) return;
    final number = room.roomNumber ?? room.id;
    debugPrint('ROOM $number images: ${room.imageUrls}');
    final resolved = room.imageUrls.map(resolveImageUrl).toList();
    debugPrint('ROOM $number resolved image URLs: $resolved');
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
}
