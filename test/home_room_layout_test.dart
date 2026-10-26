import 'package:atithi/models/room.dart';
import 'package:atithi/property_experience.dart';
import 'package:atithi/providers/rooms_provider.dart';
import 'package:atithi/providers/wishlist_provider.dart';
import 'package:atithi/screens/rooms/widgets/room_card.dart';
import 'package:atithi/screens/rooms/widgets/why_choose_atithi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [
    Size(360, 900),
    Size(768, 900),
    Size(1280, 1000),
    Size(1920, 1080),
  ]) {
    testWidgets('Home rooms carousel fits at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const rooms = [
        Room(
          id: 'carousel-room-103',
          roomName: 'Room 103',
          roomType: 'Deluxe',
          pricePerNight: 5000,
          capacity: 2,
          status: 'available',
        ),
        Room(
          id: 'carousel-room-102',
          roomName: 'Room 102',
          roomType: 'Deluxe',
          pricePerNight: 5000,
          capacity: 2,
          status: 'available',
        ),
        Room(
          id: 'carousel-room-101',
          roomName: 'Room 101',
          roomType: 'Deluxe',
          pricePerNight: 5000,
          capacity: 2,
          status: 'available',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomsProvider.overrideWith((ref) async => rooms),
            wishlistProvider.overrideWith(
              (ref) => throw StateError('Wishlist is not used in this test'),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size.width,
                  child: const PropertyRoomsPreview(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(
        find.byIcon(Icons.chevron_left_rounded),
        size.width < 600 ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home rooms autoplay advances forward continuously', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const rooms = [
      Room(id: 'auto-room-103', roomName: 'Room 103'),
      Room(id: 'auto-room-102', roomName: 'Room 102'),
      Room(id: 'auto-room-101', roomName: 'Room 101'),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomsProvider.overrideWith((ref) async => rooms),
          wishlistProvider.overrideWith(
            (ref) => throw StateError('Wishlist is not used in this test'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: PropertyRoomsPreview())),
      ),
    );
    await tester.pumpAndSettle();

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(controller.page?.round(), rooms.length * 1000);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(controller.page?.round(), rooms.length * 1000 + 1);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(controller.page?.round(), rooms.length * 1000 + 2);
  });

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    testWidgets('room and benefit cards fit at $size with 1.3 text scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: const TextScaler.linear(1.3),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    RoomCard(
                      room: const Room(
                        id: 'layout-room',
                        roomName: 'Premium Garden View Suite',
                        roomType: 'Suite',
                        description: 'A spacious room with modern comforts and a private balcony.',
                        pricePerNight: 7500,
                        capacity: 3,
                        amenities: ['wifi', 'tv', 'ac', 'mini_bar', 'balcony'],
                        status: 'available',
                      ),
                      isFavorite: false,
                      onFavorite: _noop,
                      onDetails: _noop,
                      onBook: _noop,
                    ),
                    const SizedBox(height: 20),
                    const WhyChooseAtithiCard(),
                    const PropertyHighlightsPreview(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('room title and category fit a compact card width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 225,
              child: RoomCard(
                room: Room(
                  id: 'compact-card-room',
                  roomName: 'Grand Atithi Heritage Suite',
                  roomType: 'Premium Heritage Family Suite',
                  description: 'A comfortable heritage stay.',
                  pricePerNight: 7500,
                  capacity: 3,
                  amenities: [],
                  status: 'available',
                ),
                onDetails: _noop,
                onBook: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact room card fits long content at enlarged text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.5),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: 225,
                child: RoomCard(
                  room: const Room(
                    id: 'long-content-room',
                    roomName: 'Heritage Grand Suite',
                    roomType: 'Suite',
                    description: 'A beautifully appointed heritage suite with a private courtyard, handcrafted furnishings, and thoughtful modern comforts for a memorable stay.',
                    pricePerNight: 12500,
                    capacity: 4,
                    amenities: [
                      'WiFi',
                      'TV',
                      'AC',
                      'Mini Bar',
                      'Balcony',
                      'Work Desk',
                      'Laundry',
                    ],
                    status: 'available',
                  ),
                  onDetails: _noop,
                  onBook: _noop,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
