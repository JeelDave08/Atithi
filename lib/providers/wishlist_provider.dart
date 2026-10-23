import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(),
);

final wishlistProvider = ChangeNotifierProvider<WishlistNotifier>((ref) {
  final notifier = WishlistNotifier(ref.watch(wishlistRepositoryProvider));
  ref.onDispose(notifier.dispose);
  return notifier;
});

class WishlistNotifier extends ChangeNotifier {
  WishlistNotifier(this._repository) {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );
    unawaited(refresh());
  }

  final WishlistRepository _repository;
  final Set<String> _roomIds = {};
  final Set<String> _inFlight = {};
  late final StreamSubscription<User?> _authSubscription;
  bool loading = true;
  String? errorMessage;
  String? get currentUserId => _repository.currentUserId;
  int get count => _roomIds.length;
  Set<String> get roomIds => Set.unmodifiable(_roomIds);
  bool isWishlisted(String roomId) => _roomIds.contains(roomId);

  Future<void> _onAuthChanged(User? user) async {
    _roomIds.clear();
    errorMessage = null;
    notifyListeners();
    await refresh();
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_pendingRoomKey);
    if (pending != null && pending.isNotEmpty) {
      await prefs.remove(_pendingRoomKey);
      await toggle(pending);
    }
  }

  Future<void> rememberAfterLogin(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRoomKey, roomId);
  }

  static const _pendingRoomKey = 'atithi_pending_wishlist_room';

  Future<void> refresh() async {
    if (_repository.currentUserId == null) {
      _roomIds.clear();
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final ids = await _repository.fetchWishlistRoomIds();
      _roomIds
        ..clear()
        ..addAll(ids);
    } catch (error, stack) {
      errorMessage = error.toString();
      if (kDebugMode) debugPrint('Wishlist refresh failed: $error\n$stack');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool?> toggle(String roomId) async {
    if (_inFlight.contains(roomId)) return null;
    if (_repository.currentUserId == null) return null;
    _inFlight.add(roomId);
    final wasSaved = _roomIds.contains(roomId);
    if (wasSaved) {
      _roomIds.remove(roomId);
    } else {
      _roomIds.add(roomId);
    }
    notifyListeners();
    try {
      if (wasSaved) {
        await _repository.remove(roomId);
      } else {
        await _repository.add(roomId);
      }
      return !wasSaved;
    } catch (error, stack) {
      if (wasSaved) {
        _roomIds.add(roomId);
      } else {
        _roomIds.remove(roomId);
      }
      errorMessage = error.toString();
      if (kDebugMode) debugPrint('Wishlist update failed: $error\n$stack');
      notifyListeners();
      return null;
    } finally {
      _inFlight.remove(roomId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
