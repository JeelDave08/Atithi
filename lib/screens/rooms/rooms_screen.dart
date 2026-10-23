import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../providers/rooms_provider.dart';
import '../../navigation/room_navigation.dart';
import '../../theme/app_colors.dart';
import '../../features/home/widgets/reveal_on_scroll.dart';
import 'widgets/room_card.dart';
import 'widgets/room_filter_bar.dart';
import 'widgets/room_search_bar.dart';
import 'widgets/rooms_header.dart';
import 'widgets/why_choose_atithi_card.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({
    this.checkIn,
    this.checkOut,
    this.adults = 2,
    this.children = 0,
    super.key,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  static bool _didDebugRowCheck = false;

  final _service = RoomService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String searchQuery = '';
  List<Room> _rooms = [];
  List<String> _categories = [];
  Set<String> _favorites = {};
  final Set<String> _amenities = {};
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
    if (kDebugMode && !_didDebugRowCheck) {
      _didDebugRowCheck = true;
      unawaited(_debugRoomRowCount());
    }
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => searchQuery = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => searchQuery = '');
  }

  List<Room> applyFilters(List<Room> rooms) {
    final rawQuery = searchQuery.toLowerCase().trim();
    final words = rawQuery
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[-\s]'), ''))
        .where((word) => word.isNotEmpty)
        .toList();
    final filtered = rooms.where((room) {
      if (_category != 'All' && room.roomType != _category) return false;
      final price = room.pricePerNight ?? 0;
      if (_price == 'Under 4000' && price >= 4000) return false;
      if (_price == '4000-6000' && (price < 4000 || price > 6000)) return false;
      if (_price == '6000+' && price <= 6000) return false;
      final capacity = room.capacity ?? 0;
      if (_capacity == '1-2' && (capacity < 1 || capacity > 2)) return false;
      if (_capacity == '3-4' && (capacity < 3 || capacity > 4)) return false;
      if (_capacity == '5+' && capacity < 5) return false;
      if (_amenities.isNotEmpty &&
          !_amenities.every((amenity) => room.amenities.contains(amenity))) {
        return false;
      }
      if (rawQuery.isEmpty) return true;
      final searchable =
          [
                room.roomNumber,
                room.roomName,
                room.roomType,
                room.description,
                ...room.amenities,
                room.bedInfo,
                if (room.capacity != null) '${room.capacity} guests',
                if (room.pricePerNight != null)
                  room.pricePerNight!.toStringAsFixed(0),
              ]
              .whereType<String>()
              .join(' ')
              .toLowerCase()
              .replaceAll(RegExp(r'[-\s]'), '');
      return words.every(searchable.contains);
    }).toList();
    switch (_sort) {
      case 'Price Low to High':
        filtered.sort(
          (a, b) => (a.pricePerNight ?? 0).compareTo(b.pricePerNight ?? 0),
        );
      case 'Price High to Low':
        filtered.sort(
          (a, b) => (b.pricePerNight ?? 0).compareTo(a.pricePerNight ?? 0),
        );
      case 'Rating':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    }
    return filtered;
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

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
    });
    try {
      if (refresh) ref.invalidate(roomsProvider);
      final results = await Future.wait([
        _service.fetchCategories(),
        ref.read(roomsProvider.future),
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
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.15).toDouble();
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(textScale)),
      child: PopScope<Object?>(
        canPop: Navigator.of(context).canPop(),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) context.go('/home');
        },
        child: Scaffold(
          backgroundColor: AppColors.cream,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.darkGold,
              onRefresh: () => _load(refresh: true),
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                            maxWidth > 700 ? 24 : 16,
                            8,
                            maxWidth > 700 ? 24 : 16,
                            0,
                          ),
                          child: RoomSearchBar(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onClear: _clearSearch,
                          ),
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
                      else if (applyFilters(_rooms).isEmpty)
                        SliverToBoxAdapter(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: searchQuery.isNotEmpty
                                ? _searchEmptyState()
                                : _state(
                                    Icons.hotel_outlined,
                                    'No rooms found',
                                    'Try changing or clearing your filters.',
                                    OutlinedButton(
                                      onPressed: _clear,
                                      child: const Text('Clear filters'),
                                    ),
                                  ),
                          ),
                        )
                      else
                        SliverToBoxAdapter(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: _buildRoomsGrid(
                              maxWidth,
                              contentWidth,
                              columns,
                              applyFilters(_rooms),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(14, 26, 14, 25),
                              child: WhyChooseAtithiCard(),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 90,
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
                searchQuery.isNotEmpty
                    ? '${applyFilters(_rooms).length} Rooms found for "$searchQuery"'
                    : maxWidth < 360
                    ? '${applyFilters(_rooms).length} Rooms'
                    : '${applyFilters(_rooms).length} Rooms Available',
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

  Widget _buildRoomsGrid(
    double maxWidth,
    double contentWidth,
    int columns,
    List<Room> rooms,
  ) => Column(
    key: ValueKey(rooms.map((room) => room.id).join(',')),
    children: [
      for (
        var rowIndex = 0;
        rowIndex < (rooms.length / columns).ceil();
        rowIndex++
      )
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: maxWidth > 700 ? 24 : 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: 12),
                      Expanded(
                        child: rowIndex * columns + column >= rooms.length
                            ? const SizedBox.shrink()
                            : RevealOnScroll(
                                delay: Duration(milliseconds: rowIndex * 120),
                                child: _buildRoomCard(
                                  context,
                                  rooms[rowIndex * columns + column],
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _searchEmptyState() => Padding(
    key: const ValueKey('search-empty'),
    padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 46,
            color: AppColors.darkGold,
          ),
          const SizedBox(height: 12),
          const Text(
            'No rooms found',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different keyword or clear filters',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.greyText, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _clearSearch,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGold,
              side: const BorderSide(color: AppColors.gold),
            ),
            child: const Text('Clear Search'),
          ),
        ],
      ),
    ),
  );

  Widget _buildRoomCard(BuildContext context, Room room) {
    final today = DateTime.now();
    final checkIn =
        widget.checkIn ?? DateTime(today.year, today.month, today.day);
    final requestedCheckOut = widget.checkOut;
    final checkOut =
        requestedCheckOut != null && requestedCheckOut.isAfter(checkIn)
        ? requestedCheckOut
        : checkIn.add(const Duration(days: 1));
    return RepaintBoundary(
      key: ValueKey(room.id),
      child: RoomCard(
        key: ValueKey(room.id),
        room: room,
        isFavorite: _favorites.contains(room.id),
        onFavorite: () => _favorite(room),
        onDetails: () => openRoomDetails(
          context,
          room,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          adults: widget.adults,
          children: widget.children,
        ),
        onBook: () => openRoomBooking(
          context,
          room,
          checkIn: checkIn,
          checkOut: checkOut,
          adults: widget.adults,
          children: widget.children,
        ),
      ),
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
