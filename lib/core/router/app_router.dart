import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_repository.dart';
import '../../features/availability/availability_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/profile_screen.dart';
import '../../features/property/property.dart';
import '../../features/property/property_screen.dart';
import '../../property_experience.dart';
import '../../screens/auth_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/rooms/rooms_screen.dart';

final authRepositoryProvider = Provider<AuthService>(
  (ref) => const AuthService(),
);
final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => MockPropertyRepository(),
);

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = _AuthRefreshListenable(auth.authStateChanges());
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final location = state.matchedLocation;
      if (location == '/splash') return null;
      final user = await auth.currentUserId();
      const authLocations = {'/auth', '/register', '/forgot-password'};
      if (user == null && !authLocations.contains(location)) return '/auth';
      if (user != null && authLocations.contains(location)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            SplashScreen(currentUser: auth.currentUserId),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthScreen(authRepository: auth),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(authRepository: auth),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(authRepository: auth),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/property',
        builder: (context, state) => const PropertyScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const PropertyAboutScreen(),
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const PropertyServicesScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const PropertyContactScreen(),
      ),
      GoRoute(path: '/rooms', builder: (context, state) => const RoomsScreen()),
      GoRoute(
        path: '/availability',
        builder: (context, state) => AvailabilityScreen(
          property: ref.read(propertyRepositoryProvider).featured,
        ),
      ),
      GoRoute(
        path: '/coming/:tab',
        builder: (context, state) =>
            ComingSoonScreen(tab: state.pathParameters['tab'] ?? 'More'),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

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
