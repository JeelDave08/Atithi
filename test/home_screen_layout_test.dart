import 'package:atithi/atithi_home_screen.dart';
import 'package:atithi/providers/rooms_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://127.0.0.1:1',
      publishableKey: 'test',
    );
  });
  for (final size in const [Size(360, 800), Size(1440, 1000)]) {
    testWidgets('Home layout has no overflow at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roomsProvider.overrideWith((ref) async => const [])],
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: const MaterialApp(home: AtithiHomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATITHI'), findsOneWidget);
      expect(find.text('More than\njust a stay'), findsOneWidget);
      expect(find.text('Find a stay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
