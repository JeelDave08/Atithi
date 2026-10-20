import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import 'login_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({required this.authRepository, super.key});
  final AuthRepository authRepository;
  @override
  Widget build(BuildContext context) =>
      LoginScreen(authRepository: authRepository);
}
