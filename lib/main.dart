import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

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
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = media.textScaler.scale(1).clamp(0.9, 1.15).toDouble();
        Widget app = MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: ScrollConfiguration(
            behavior: const _AtithiScrollBehavior(),
            child: child ?? const SizedBox.shrink(),
          ),
        );
        if (kIsWeb) {
          app = ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320),
            child: app,
          );
        }
        return app;
      },
    );
  }
}

class _AtithiScrollBehavior extends MaterialScrollBehavior {
  const _AtithiScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
