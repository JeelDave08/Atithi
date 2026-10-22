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
}

void _noop() {}
