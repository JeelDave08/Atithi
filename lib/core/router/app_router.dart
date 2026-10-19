import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/property/property.dart';
import '../../features/property/property_screen.dart';
import '../../features/availability/availability_screen.dart';
import '../../features/splash/splash_screen.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);
final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => MockPropertyRepository(),
);
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      if (state.matchedLocation == '/splash') return null;
      final user = await auth.currentUser();
      final atAuth = state.matchedLocation == '/auth';
      if (user == null && !atAuth) return '/auth';
      if (user != null && atAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            SplashScreen(currentUser: auth.currentUser),
      ),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/property', builder: (c, s) => const PropertyScreen()),
      GoRoute(
        path: '/availability',
        builder: (c, s) => AvailabilityScreen(
          property: ref.read(propertyRepositoryProvider).featured,
        ),
      ),
      GoRoute(
        path: '/coming/:tab',
        builder: (c, s) =>
            ComingSoonScreen(tab: s.pathParameters['tab'] ?? 'More'),
      ),
    ],
  );
});

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({required this.tab, super.key});
  final String tab;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B2447),
    body: SafeArea(
      child: Center(
        child: Text(
          '$tab · Coming soon',
          style: const TextStyle(color: Color(0xFFFBF6EC), fontSize: 20),
        ),
      ),
    ),
  );
}
