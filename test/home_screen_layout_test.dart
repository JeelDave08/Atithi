import 'package:atithi/atithi_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(360, 800), Size(1440, 1000)]) {
    testWidgets('Home layout has no overflow at $size', (tester) async {
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
          child: const MaterialApp(home: AtithiHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATITHI'), findsOneWidget);
      expect(find.text('More than just a stay'), findsOneWidget);
      expect(find.text('Find a stay  →'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
