import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';

class WishlistRepository {
  WishlistRepository({FirebaseAuth? auth, SupabaseClient? client})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? Supabase.instance.client;

  final FirebaseAuth _auth;
  final SupabaseClient _client;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<Set<String>> fetchWishlistRoomIds() async {
    final uid = currentUserId;
    if (uid == null) return {};
    final rows = await _client
        .from('wishlists')
        .select('room_id')
        .eq('user_id', uid);
    return rows.map((row) => row['room_id'].toString()).toSet();
  }

  Future<void> add(String roomId) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Please sign in to save rooms.');
    try {
      await _client.from('wishlists').insert({
        'user_id': uid,
        'room_id': roomId,
      });
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
    }
  }

  Future<void> remove(String roomId) async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Please sign in to save rooms.');
    await _client
        .from('wishlists')
        .delete()
        .eq('user_id', uid)
        .eq('room_id', roomId);
  }

  Future<List<Room>> fetchWishlistRooms() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _client
        .from('wishlists')
        .select('created_at, rooms(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    final rooms = <Room>[];
    for (final row in rows) {
      final joined = row['rooms'];
      final values = joined is Map<String, dynamic>
          ? [joined]
          : joined is List
          ? joined.whereType<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[];
      for (final value in values) {
        try {
          rooms.add(Room.fromJson(value));
        } catch (error) {
          if (kDebugMode) debugPrint('Wishlist room parse failed: $error');
        }
      }
    }
    return rooms;
  }
}
