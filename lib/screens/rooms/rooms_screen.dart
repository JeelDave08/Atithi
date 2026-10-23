import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/room.dart';
import '../../core/navigation/app_shell.dart';
import '../../core/responsive/breakpoints.dart';
import '../../services/room_service.dart';
import '../../providers/rooms_provider.dart';
import '../../navigation/room_navigation.dart';
import '../../theme/app_colors.dart';
import '../../features/home/widgets/reveal_on_scroll.dart';
import 'widgets/room_card.dart';
import 'widgets/room_filter_bar.dart';
import 'widgets/room_filters_sheet.dart';
import 'widgets/room_search_bar.dart';
import 'widgets/rooms_header.dart';
import 'widgets/why_choose_atithi_card.dart';
import 'models/room_filters.dart';

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
  bool _loading = true;
  Object? _error;
  String? _debugError;
  RoomFilters _filters = const RoomFilters();

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

  List<Room> get _filteredRooms => applyFilters(_rooms, _filters, searchQuery);

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
      final rooms = await ref.read(roomsProvider.future);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
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

  void _clear() {
    setState(() => _filters = _filters.clear());
  }

  Future<void> _openFilters() async {
    final result = await showRoomFilters(
      context: context,
      rooms: _rooms,
      initial: _filters,
      searchQuery: searchQuery,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
  }

  void _removeType(String value) => setState(() {
    _filters = _filters.copyWith(types: {..._filters.types}..remove(value));
  });
  void _removeAmenity(String value) => setState(() {
    _filters = _filters.copyWith(
      amenities: {..._filters.amenities}..remove(value),
    );
  });

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
        child: AppShell(
          activeRoute: '/rooms',
          body: SafeArea(
            top: false,
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.darkGold,
              onRefresh: () => _load(refresh: true),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final screenWidth = context.screenWidth;
                  final columns = screenWidth < 600
                      ? 1
                      : screenWidth < 1024
                      ? 2
                      : screenWidth < 1440
                      ? 3
                      : 4;
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
                          padding: const EdgeInsets.only(top: 8),
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
                            isActive: _filters.isActive,
                            activeCount: _filters.activeCount,
                            onAll: _clear,
                            onFilters: _openFilters,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildResultsRow(maxWidth, contentWidth),
                      ),
                      if (_filters.isActive)
                        SliverToBoxAdapter(
                          child: _activeFilterChips(contentWidth),
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
                      else if (_filteredRooms.isEmpty)
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
                                      child: const Text('Clear Filters'),
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
                              _filteredRooms,
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
                _filters.isActive || searchQuery.isNotEmpty
                    ? '${_filteredRooms.length} Rooms found'
                    : '${_filteredRooms.length} Rooms Available',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _activeFilterChips(double maxWidth) {
    final chips = <Widget>[
      for (final type in _filters.types)
        _removableChip(type, () => _removeType(type)),
      if (_filters.price case final range?)
        _removableChip(
          '₹${range.start.round()}-₹${range.end.round()}',
          () => setState(() => _filters = _filters.copyWith(clearPrice: true)),
        ),
      if (_filters.guests case final guests?)
        _removableChip(
          '$guests+ guests',
          () => setState(() => _filters = _filters.copyWith(clearGuests: true)),
        ),
      for (final amenity in _filters.amenities)
        _removableChip(amenity, () => _removeAmenity(amenity)),
      if (_filters.sort != SortOption.recommended)
        _removableChip(
          switch (_filters.sort) {
            SortOption.priceLowHigh => 'Price low-high',
            SortOption.priceHighLow => 'Price high-low',
            SortOption.rating => 'Rating',
            SortOption.recommended => 'Recommended',
          },
          () => setState(
            () => _filters = _filters.copyWith(sort: SortOption.recommended),
          ),
        ),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, index) => chips[index],
          ),
        ),
      ),
    );
  }

  Widget _removableChip(String label, VoidCallback onRemove) => InputChip(
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    onDeleted: onRemove,
    deleteIcon: const Icon(Icons.close_rounded, size: 16),
    backgroundColor: AppColors.cream,
    side: const BorderSide(color: AppColors.gold),
    labelStyle: const TextStyle(color: AppColors.navy, fontSize: 12),
    visualDensity: VisualDensity.compact,
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
