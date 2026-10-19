import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/auth_repository.dart' as firebase;

abstract interface class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> signOut();
  Future<String?> currentUser();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({firebase.AuthService? service})
    : _service = service ?? const firebase.AuthService();

  final firebase.AuthService _service;

  @override
  Future<String?> currentUser() async => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _service.signInWithEmail(email, password);

  @override
  Future<void> signUp({required String name, required String email, required String phone, required String password}) =>
      _service.signUpWithEmail(name, email, phone, '', password);

  @override
  Future<void> signOut() => _service.signOut();
}
