import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthFailureCode {
  emailAlreadyInUse,
  invalidCredentials,
  cancelled,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);
  final AuthFailureCode code;
  final String message;
  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String countryCode,
    required String password,
  });
  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  });
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Stream<User?> authStateChanges();
}

class AuthService implements AuthRepository {
  const AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  static const _rememberKey = 'atithi_remember_me';
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitialization;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signUpWithEmail(
    String name,
    String email,
    String phone,
    String countryCode,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthFailure(AuthFailureCode.unknown, 'Account creation failed. Please try again.');
      await user.updateDisplayName(name.trim());
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': user.email ?? email.trim(),
        'phone': phone,
        'countryCode': countryCode,
        'photoUrl': user.photoURL,
        'createdAt': now,
        'lastLogin': now,
      });
      await _remember(true);
    } on FirebaseAuthException catch (e) {
      _logAuthError(e);
      throw _toAuthFailure(e);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password, {bool rememberMe = true}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _remember(rememberMe);
      final user = credential.user;
      if (user != null) await _updateLastLogin(user);
    } on FirebaseAuthException catch (e) {
      _logAuthError(e);
      throw _toAuthFailure(e);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _googleInitialization ??= _googleSignIn.initialize();
      await _googleInitialization;
      final account = await _googleSignIn.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) await _ensureGoogleUserDocument(user);
      await _remember(true);
    } on FirebaseAuthException catch (e) {
      _logAuthError(e);
      throw _toAuthFailure(e);
    } on GoogleSignInException catch (e) {
      debugPrint('Google sign-in error: ${e.code} - ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure(AuthFailureCode.cancelled, 'Google sign-in was cancelled.');
      }
      throw AuthFailure(AuthFailureCode.unknown, e.description ?? 'Google sign-in failed. Please try again.');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      _logAuthError(e);
      throw _toAuthFailure(e);
    }
  }

  @override
  Future<void> register({required String fullName, required String email, required String phoneNumber, required String countryCode, required String password}) =>
      signUpWithEmail(fullName, email, phoneNumber, countryCode, password);

  @override
  Future<void> signIn({required String email, required String password, required bool rememberMe}) =>
      signInWithEmail(email, password, rememberMe: rememberMe);

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _remember(false);
  }

  Future<void> _remember(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_rememberKey, value);
  }

  Future<void> _updateLastLogin(User user) => _firestore
      .collection('users')
      .doc(user.uid)
      .set({'lastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true));

  Future<void> _ensureGoogleUserDocument(User user) async {
    final reference = _firestore.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    final now = FieldValue.serverTimestamp();
    if (!snapshot.exists) {
      await reference.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'countryCode': '',
        'photoUrl': user.photoURL,
        'createdAt': now,
        'lastLogin': now,
      });
    } else {
      await reference.set({'lastLogin': now}, SetOptions(merge: true));
    }
  }

  void _logAuthError(FirebaseAuthException e) => debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

  AuthFailure _toAuthFailure(FirebaseAuthException e) {
    final message = switch (e.code) {
      'user-not-found' => 'No account was found for that email.',
      'wrong-password' => 'The password is incorrect.',
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'This email is already registered. Try signing in instead.',
      'weak-password' => 'Choose a stronger password with at least 6 characters.',
      'invalid-email' => 'Enter a valid email address.',
      'network-request-failed' => 'Unable to connect. Check your connection and try again.',
      _ => 'Authentication failed. Please try again.',
    };
    final code = switch (e.code) {
      'email-already-in-use' => AuthFailureCode.emailAlreadyInUse,
      'wrong-password' || 'user-not-found' || 'invalid-credential' => AuthFailureCode.invalidCredentials,
      'network-request-failed' => AuthFailureCode.network,
      _ => AuthFailureCode.unknown,
    };
    return AuthFailure(code, message);
  }
}
