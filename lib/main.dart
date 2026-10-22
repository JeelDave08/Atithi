import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    accessToken: () async =>
        await FirebaseAuth.instance.currentUser?.getIdToken(),
  );

  try {
    await Supabase.instance.client.from('rooms').select('id').limit(1);
    debugPrint('Supabase OK');
  } catch (error) {
    debugPrint('Supabase health check failed: $error');
  }

  runApp(const ProviderScope(child: AtithiApp()));
}
**Validation:** Authentication UI tests passed. `flutter analyze` reports 26 info-level lints, including the SDK deprecation notice for the requested `anonKey` parameter; it reports no compile errors.

From `D:\Atithi`, run `flutter clean`, then `flutter pub get`, then fully stop and restart the app (not hot reload).
**Validation:** Authentication UI tests passed. `flutter analyze` reports 26 info-level lints, including the SDK deprecation notice for the requested `anonKey` parameter; it reports no compile errors.

From `D:\Atithi`, run `flutter clean`, then `flutter pub get`, then fully stop and restart the app (not hot reload).

class AtithiApp extends ConsumerWidget {
  const AtithiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Atithi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
