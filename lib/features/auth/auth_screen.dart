import 'package:flutter/material.dart';

import '../../auth/auth_repository.dart';
import '../../screens/login_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      LoginScreen(authRepository: const AuthService());
}
