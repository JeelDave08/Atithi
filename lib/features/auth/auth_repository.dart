import 'package:shared_preferences/shared_preferences.dart';

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

class MockAuthRepository implements AuthRepository {
  static const _key = 'atithi_user_email';
  @override
  Future<String?> currentUser() async =>
      (await SharedPreferences.getInstance()).getString(_key);
  @override
  Future<void> signIn({required String email, required String password}) async {
    await (await SharedPreferences.getInstance()).setString(_key, email);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => signIn(email: email, password: password);
  @override
  Future<void> signOut() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
