import 'package:atithi/models/room.dart';
import 'package:atithi/property_experience.dart';
import 'package:atithi/screens/rooms/widgets/room_card.dart';
import 'package:atithi/screens/rooms/widgets/why_choose_atithi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
                    description:
                        'A beautifully appointed heritage suite with a private courtyard, handcrafted furnishings, and thoughtful modern comforts for a memorable stay.',
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
