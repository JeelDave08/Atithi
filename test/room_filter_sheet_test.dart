import 'package:atithi/screens/rooms/models/room_filters.dart';
import 'package:atithi/screens/rooms/widgets/room_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('room filters count active selections', () {
    const filters = RoomFilters(types: {'Deluxe'}, guests: 3);
    expect(filters.isActive, isTrue);
    expect(filters.activeCount, 2);
  });

  testWidgets('room filter bar invokes the All callback', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var allPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.8),
            viewInsets: EdgeInsets.only(bottom: 180),
          ),
          child: Scaffold(
            body: Center(
              child: RoomFilterBar(
                isActive: true,
                activeCount: 2,
                onAll: () => allPressed = true,
                onFilters: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(allPressed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
