import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../theme/app_colors.dart';
import '../../features/home/widgets/reveal_on_scroll.dart';
import 'widgets/room_card.dart';
import 'widgets/room_filter_bar.dart';
import 'widgets/rooms_header.dart';
import 'widgets/why_choose_atithi_card.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  static bool _didDebugRowCheck = false;

  final _service = RoomService();
  List<Room> _rooms = [];
  List<String> _categories = [];
  Set<String> _favorites = {};
  final Set<String> _amenities = {};
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);
  bool _loading = true;
  Object? _error;
  String? _debugError;
  String _category = 'All';
  String _sort = 'Recommended';
  String? _price;
  String? _capacity;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateParallaxOffset);
    if (kDebugMode && !_didDebugRowCheck) {
      _didDebugRowCheck = true;
      unawaited(_debugRoomRowCount());
    }
    _load();
  }

  void _updateParallaxOffset() {
    if (_scrollOffset.value != _scrollController.offset) {
      _scrollOffset.value = _scrollController.offset;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateParallaxOffset)
      ..dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  Future<void> _debugRoomRowCount() async {
    try {
      final count = await _service.debugRoomRowCount();
      debugPrint(
        'Rooms startup check: $count rows returned by rooms select(id).',
      );
    } catch (error, stack) {
      debugPrint('Rooms startup check error: $error\n$stack');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchCategories(),
        _service.fetchRooms(
          roomType: _category,
          priceRange: _price,
          capacityRange: _capacity,
          amenities: _amenities,
          sort: _sort,
        ),
      ]);
      final user = FirebaseAuth.instance.currentUser;
      final favorites = user == null
          ? <String>{}
          : await _service.fetchFavoriteIds(user.uid);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<String>;
        _rooms = results[1] as List<Room>;
        _favorites = favorites;
        _error = null;
        _debugError = null;
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('Rooms load error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _error = e;
        if (kDebugMode) {
          _debugError = '$e\n$stack';
        }
        _loading = false;
      });
    }
  }

  Future<void> _favorite(Room room) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save your favorite rooms.'),
        ),
      );
      return;
    }

    final wasFavorite = _favorites.contains(room.id);
    setState(() {
      if (wasFavorite) {
        _favorites.remove(room.id);
      } else {
        _favorites.add(room.id);
      }
    });

    try {
      await _service.toggleFavorite(user.uid, room.id, isFavorite: wasFavorite);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favorites.add(room.id);
        } else {
          _favorites.remove(room.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorite.')),
      );
    }
  }

  void _apply(String selection) {
    final parts = selection.split('=');
    if (parts.length != 2) return;

    setState(() {
      switch (parts[0]) {
        case 'Price Range':
          _price = parts[1] == 'Any' ? null : parts[1];
        case 'Capacity':
          _capacity = parts[1] == 'Any' ? null : parts[1];
        case 'Room Type':
          _category = parts[1] == 'Any' ? 'All' : parts[1];
        case 'Amenities':
          if (_amenities.contains(parts[1])) {
            _amenities.remove(parts[1]);
          } else {
            _amenities.add(parts[1]);
          }
      }
    });
    _load();
  }

  void _clear() {
    setState(() {
      _price = null;
      _capacity = null;
      _category = 'All';
      _amenities.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.darkGold,
            onRefresh: _load,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final columns = maxWidth < 600
                    ? 1
                    : maxWidth < 900
                    ? 2
                    : 3;
                final contentWidth = maxWidth > 1200 ? 1160.0 : maxWidth;

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: RoomsHeader(
                        imageUrl:
                            _rooms.isNotEmpty &&
                                _rooms.first.imageUrls.isNotEmpty
                            ? _rooms.first.imageUrls.first
                            : null,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          maxWidth > 700 ? 24 : 14,
                          12,
                          maxWidth > 700 ? 24 : 14,
                          12,
                        ),
                        child: RoomFilterBar(
                          categories: _categories,
                          category: _category,
                          price: _price,
                          type: _category == 'All' ? null : _category,
                          capacity: _capacity,
                          amenities: _amenities,
                          onCategory: (category) {
                            setState(() => _category = category);
                            _load();
                          },
                          onFilter: _apply,
                          onClear: _clear,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildResultsRow(maxWidth, contentWidth),
                    ),
                    if (_loading)
                      SliverToBoxAdapter(
                        child: _skeletonGrid(maxWidth, columns, contentWidth),
                      )
                    else if (_error != null)
                      SliverToBoxAdapter(
                        child: _state(
                          Icons.wifi_off,
                          'Could not load rooms',
                          'Please check your connection and try again.',
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                          debugDetails: kDebugMode ? _debugError : null,
                        ),
                      )
                    else if (_rooms.isEmpty)
                      SliverToBoxAdapter(
                        child: _state(
                          Icons.hotel_outlined,
                          'No rooms found',
                          'Try changing or clearing your filters.',
                          OutlinedButton(
                            onPressed: _clear,
                            child: const Text('Clear filters'),
                          ),
                        ),
                      )
                    else
                      _buildRoomsGrid(maxWidth, contentWidth),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: RevealOnScroll(
                            slideFrom: const Offset(-.15, 0),
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(14, 26, 14, 25),
                              child: WhyChooseAtithiCard(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 100,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: const _RoomsNavigation(),
      ),
    );
  }

  Widget _buildResultsRow(double maxWidth, double contentWidth) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: contentWidth),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          maxWidth > 700 ? 24 : 16,
          0,
          maxWidth > 700 ? 24 : 16,
          15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.bed_outlined, color: AppColors.darkGold, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                maxWidth < 360
                    ? '${_rooms.length} Rooms'
                    : '${_rooms.length} Rooms Available',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _sort,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.navy,
                  ),
                  selectedItemBuilder: (context) => const [
                    _SortLabel('Recommended'),
                    _SortLabel('Price ↑'),
                    _SortLabel('Price ↓'),
                    _SortLabel('Rating'),
                  ],
                  items:
                      [
                        'Recommended',
                        'Price Low to High',
                        'Price High to Low',
                        'Rating',
                      ].map((sort) {
                        return DropdownMenuItem(
                          value: sort,
                          child: Text(
                            sort,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                  onChanged: (sort) {
                    if (sort == null) return;
                    setState(() => _sort = sort);
                    _load();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // SliverList builds room cards lazily so each reveal runs as it enters view.
  Widget _buildRoomsGrid(double maxWidth, double contentWidth) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final room = _rooms[index];
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                maxWidth > 700 ? 24 : 14,
                index == 0 ? 0 : 12,
                maxWidth > 700 ? 24 : 14,
                0,
              ),
              child: RevealOnScroll(
                delay: Duration(milliseconds: index * 120),
                child: _PressScale(
                  child: RoomCard(
                    room: room,
                    scrollOffset: _scrollOffset,
                    isFavorite: _favorites.contains(room.id),
                    onFavorite: () => _favorite(room),
                    onDetails: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            RoomDetailsScreen(roomId: room.id, room: room),
                      ),
                    ),
                    onBook: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RoomBookingPlaceholder(room: room),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }, childCount: _rooms.length),
    );
  }

  Widget _state(
    IconData icon,
    String title,
    String subtitle,
    Widget button, {
    String? debugDetails,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.darkGold),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.greyText),
          ),
          if (debugDetails != null && debugDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(
              debugDetails,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.greyText, fontSize: 10),
            ),
          ],
          const SizedBox(height: 14),
          button,
        ],
      ),
    );
  }

  Widget _skeletonGrid(double width, int columns, double maxWidth) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(columns * 2, (_) {
              return SizedBox(
                width: (width - 28 - (columns - 1) * 12) / columns,
                child: Shimmer.fromColors(
                  baseColor: const Color(0xFFE9E2D5),
                  highlightColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.42,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(height: 13, width: 120, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 9, width: 90, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 9, width: 150, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(
                        height: 26,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        height: 32,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _RoomsNavigation extends StatelessWidget {
  const _RoomsNavigation();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.cream,
      boxShadow: [
        BoxShadow(
          color: Color(0x160F2943),
          blurRadius: 12,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _item(
              context,
              Icons.home_outlined,
              'Home',
              () => context.go('/home'),
            ),
            _item(context, Icons.bed_outlined, 'Rooms', null, true),
            _item(
              context,
              Icons.event_note_outlined,
              'Bookings',
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    body: Center(
                      child: Text('Booking history will appear here.'),
                    ),
                  ),
                ),
              ),
            ),
            _item(
              context,
              Icons.person_outline_rounded,
              'Profile',
              () => context.go('/profile'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap, [
    bool selected = false,
  ]) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? AppColors.darkGold : AppColors.greyText,
            size: 21,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.navy : AppColors.greyText,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SortLabel extends StatelessWidget {
  const _SortLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.sort, size: 15, color: AppColors.navy),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _pressed = true),
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed && !MediaQuery.disableAnimationsOf(context) ? .97 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({
    required this.roomId,
    required this.room,
    super.key,
  });

  final String roomId;
  final Room room;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: const Text('Room Details'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (room.imageUrls.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              room.imageUrls.first,
              height: 230,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) =>
                  const SizedBox(height: 230, child: Icon(Icons.bed_outlined)),
            ),
          ),
        Text(
          room.roomName ?? 'Room',
          style: const TextStyle(
            fontSize: 26,
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (room.description != null) Text(room.description!),
        Text('₹${room.pricePerNight?.toStringAsFixed(0) ?? '—'} / night'),
      ],
    ),
  );
}

class RoomBookingPlaceholder extends StatelessWidget {
  const RoomBookingPlaceholder({required this.room, super.key});

  final Room room;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: const Text('Book your stay'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Booking flow is not available yet.\n\n'
          '${room.roomName ?? 'Room'} · '
          '₹${room.pricePerNight?.toStringAsFixed(0) ?? '—'} / night',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.navy, fontSize: 18),
        ),
      ),
    ),
  );
}
