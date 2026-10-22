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
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 100 * 1024 * 1024
    ..maximumSize = 200;

  if (!SupabaseConfig.isConfigured) {
    throw StateError(
      'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with --dart-define.',
    );
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  try {
    await Supabase.instance.client.from('rooms').select('id').limit(1);
    debugPrint('Supabase OK');
  } catch (error) {
    debugPrint('Supabase health check failed: $error');
  }

  runApp(const ProviderScope(child: AtithiApp()));
}

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
