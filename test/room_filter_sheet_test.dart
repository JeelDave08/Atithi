import 'package:atithi/screens/rooms/widgets/room_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('room types are deduplicated and alphabetically sorted', () {
    expect(
      RoomFilters.uniqueRoomTypes([
        ' deluxe room ',
        'Deluxe',
        'Family Suite',
        'Family',
        'Standard Room',
        'Executive',
      ]),
      ['Deluxe', 'Executive', 'Family', 'Standard Room'],
    );
  });

  testWidgets('filter sheet scrolls on a compact keyboard-inset viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    RoomFilters? applied;
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
                categories: const ['Deluxe', 'Family', 'Standard Room'],
                category: 'All',
                filters: RoomFilters(priceRanges: {'Under 4000'}),
                onCategory: (_) {},
                onApply: (value) => applied = value,
                resultCount: (_) => 12,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('1 filter'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(applied?.isEmpty, isTrue);
    expect(find.text('1 filter'), findsNothing);
    expect(find.text('Show 12 rooms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
