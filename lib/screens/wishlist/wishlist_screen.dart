import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_shell.dart';
import '../../core/responsive/app_container.dart';
import '../../models/room.dart';
import '../../navigation/room_navigation.dart';
import '../../providers/wishlist_provider.dart';
import '../../screens/rooms/widgets/room_card.dart';
import '../../theme/app_colors.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  List<Room> _rooms = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(wishlistProvider);
      await notifier.refresh();
      final rooms = await ref
          .read(wishlistRepositoryProvider)
          .fetchWishlistRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(wishlistProvider);
    if (FirebaseAuth.instance.currentUser == null) {
      return AppShell(
        activeRoute: '/profile',
        body: Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: const Text('My Wishlist'),
            leading: IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 52,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Login to see your wishlist',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final visibleRooms = _rooms
        .where((room) => notifier.isWishlisted(room.id))
        .toList();
    return AppShell(
      activeRoute: '/profile',
      wrapInContainer: false,
      body: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.navy,
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text(
            'My Wishlist',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: AppContainer(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: RefreshIndicator(
              color: AppColors.gold,
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_loading) return _loadingState();
                  if (_error != null) {
                    return _message(
                      icon: Icons.cloud_off_outlined,
                      title: 'Wishlist could not be loaded',
                      subtitle: 'Check your connection and try again.',
                      button: OutlinedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    );
                  }
                  if (visibleRooms.isEmpty) {
                    return _message(
                      icon: Icons.favorite_border_rounded,
                      title: 'Your wishlist is empty',
                      subtitle: 'Save rooms you love and find them here',
                      button: FilledButton(
                        onPressed: () => context.go('/rooms'),
                        child: const Text('Explore Rooms'),
                      ),
                    );
                  }
                  final width = constraints.maxWidth;
                  final columns = width >= 1440
                      ? 4
                      : width >= 1024
                      ? 3
                      : width >= 600
                      ? 2
                      : 1;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: GridView.builder(
                      key: ValueKey(
                        visibleRooms.map((room) => room.id).join(','),
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 104),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: columns == 1
                            ? .82
                            : columns == 2
                            ? .72
                            : .62,
                      ),
                      itemCount: visibleRooms.length,
                      itemBuilder: (context, index) {
                        final room = visibleRooms[index];
                        return RoomCard(
                          key: ValueKey(room.id),
                          room: room,
                          onDetails: () => openRoomDetails(context, room),
                          onBook: () => openRoomBooking(context, room),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingState() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(top: 24, bottom: 104),
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          height: 340,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
    ],
  );

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget button,
  }) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 104),
    children: [
      SizedBox(height: MediaQuery.sizeOf(context).height * .2),
      Icon(icon, size: 54, color: AppColors.gold),
      const SizedBox(height: 14),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.greyText),
      ),
      const SizedBox(height: 18),
      Center(child: button),
    ],
  );
}
