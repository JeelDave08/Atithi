import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';

class WishlistRepository {
  WishlistRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<Set<String>> fetchWishlistRoomIds() async {
    try {
      final uid = currentUserId;
      if (uid == null) return {};
      final rows = await _client
          .from('wishlists')
          .select('room_id')
          .eq('user_id', uid);
      return rows.map((row) => row['room_id'].toString()).toSet();
    } catch (error) {
      _logError('fetch ids', error);
      rethrow;
    }
  }

  Future<void> add(String roomId) async {
    try {
      final uid = currentUserId;
      if (uid == null) throw StateError('Please sign in to save rooms.');
      await _client
          .from('wishlists')
          .upsert(
            {'user_id': uid, 'room_id': roomId},
            onConflict: 'user_id,room_id',
            ignoreDuplicates: true,
          );
    } catch (error) {
      _logError('add room $roomId', error);
      rethrow;
    }
  }

  Future<void> remove(String roomId) async {
    try {
      final uid = currentUserId;
      if (uid == null) throw StateError('Please sign in to save rooms.');
      await _client
          .from('wishlists')
          .delete()
          .eq('user_id', uid)
          .eq('room_id', roomId);
    } catch (error) {
      _logError('remove room $roomId', error);
      rethrow;
    }
  }

  Future<List<Room>> fetchWishlistRooms() async {
    try {
      if (currentUserId == null) return [];
      List<dynamic> rows;
      try {
        rows = await _client
            .from('wishlists')
            .select('created_at, rooms(*)')
            .eq('user_id', currentUserId!)
            .order('created_at', ascending: false);
      } on PostgrestException catch (error) {
        _logError('fetch joined rooms; retrying by ids', error);
        final ids = await fetchWishlistRoomIds();
        if (ids.isEmpty) return [];
        final fallback = await _client
            .from('rooms')
            .select()
            .inFilter('id', ids.toList());
        rows = fallback.map((room) => {'rooms': room}).toList();
      }
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
    } catch (error) {
      _logError('fetch rooms', error);
      rethrow;
    }
  }

  void _logError(String operation, Object error) {
    if (!kDebugMode) return;
    debugPrint('WISHLIST ERROR: $error ($operation)');
    if (error is PostgrestException) {
      debugPrint(
        'code=${error.code} msg=${error.message} details=${error.details}',
      );
    }
    final message = error.toString().toLowerCase();
    if (error is TimeoutException ||
        message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('failed host lookup')) {
      debugPrint('WISHLIST NETWORK ERROR: $error');
    }
  }
}
