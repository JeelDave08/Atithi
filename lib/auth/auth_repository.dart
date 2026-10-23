import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/constants.dart';

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

enum GoogleSignInStatus { success, cancelled, error }

class GoogleSignInResult {
  const GoogleSignInResult._(this.status, {this.message});

  const GoogleSignInResult.success() : this._(GoogleSignInStatus.success);

  const GoogleSignInResult.cancelled()
    : this._(
        GoogleSignInStatus.cancelled,
        message: 'Google sign-in was cancelled.',
      );

  const GoogleSignInResult.error(String message)
    : this._(GoogleSignInStatus.error, message: message);

  final GoogleSignInStatus status;
  final String? message;
}

abstract interface class AuthRepository {
  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String countryCode,
    String countryIso = 'IN',
    required String password,
  });
  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  });
  Future<GoogleSignInResult> signInWithGoogle();
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
  sb.SupabaseClient get _supabase => sb.Supabase.instance.client;
  static const _rememberKey = 'atithi_remember_me';
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleSignInInitialized = false;
  static Future<void>? _googleInitialization;

  static Future<void> initializeGoogleSignIn() {
    if (_googleSignInInitialized) return Future<void>.value();
    return _googleInitialization ??= _initializeGoogleSignIn();
  }

  static Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        clientId: kIsWeb ? googleWebClientId : null,
        serverClientId: kIsWeb ? null : googleWebClientId,
      );
      _googleSignInInitialized = true;
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<String?> currentUserId() async =>
      _auth.currentUser == null || _supabase.auth.currentSession == null
      ? null
      : _supabase.auth.currentUser?.id;

  Future<void> signUpWithEmail(
    String name,
    String email,
    String phone,
    String countryCode,
    String password, {
    String countryIso = 'IN',
  }) async {
    try {
      await _supabase.auth.signUp(email: email.trim(), password: password);
      if (_supabase.auth.currentSession == null) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          'Please verify your email to finish setting up your account, then sign in again.',
        );
      }
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          'Account creation failed. Please try again.',
        );
      }
      await user.updateDisplayName(name.trim());
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': user.email ?? email.trim(),
        'phone': phone,
        'countryCode': countryCode,
        'countryIso': countryIso,
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
    } on sb.AuthException catch (e) {
      debugPrint('Supabase auth error: ${e.code} - ${e.message}');
      throw AuthFailure(AuthFailureCode.unknown, e.message);
    }
  }

  Future<void> signInWithEmail(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      try {
        await _supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      } on sb.AuthException catch (e) {
        if (e.code == 'invalid_credentials' ||
            e.message.toLowerCase().contains('invalid login credentials')) {
          // Migrate existing Firebase-only accounts using the same credentials.
          try {
            final provisioned = await _supabase.auth.signUp(
              email: email.trim(),
              password: password,
            );
            if (provisioned.session == null) {
              throw const AuthFailure(
                AuthFailureCode.unknown,
                'Please verify your email to finish setting up wishlist access.',
              );
            }
          } on sb.AuthException catch (provisionError) {
            if (provisionError.message.toLowerCase().contains('already')) {
              throw const AuthFailure(
                AuthFailureCode.invalidCredentials,
                'Email or password is incorrect.',
              );
            }
            rethrow;
          }
        } else {
          rethrow;
        }
      }
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
    } on sb.AuthException catch (e) {
      debugPrint('Supabase auth error: ${e.code} - ${e.message}');
      throw AuthFailure(AuthFailureCode.unknown, e.message);
    }
  }

  @override
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      await initializeGoogleSignIn();
      final UserCredential result;
      if (kIsWeb) {
        result = await _auth.signInWithPopup(GoogleAuthProvider());
        final oauth = result.credential as OAuthCredential?;
        final idToken = oauth?.idToken;
        if (idToken == null) {
          return const GoogleSignInResult.error(
            'Google sign-in did not provide an ID token for wishlist access.',
          );
        }
        await _supabase.auth.signInWithIdToken(
          provider: sb.OAuthProvider.google,
          idToken: idToken,
          accessToken: oauth?.accessToken,
        );
      } else {
        final account = await _googleSignIn.authenticate(
          scopeHint: const ['email', 'profile'],
        );
        final idToken = account.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          const message =
              'Google sign-in is not configured correctly. Please check SHA-1, authorized domains and google-services.json.';
          debugPrint('Google sign-in failed: ID token was missing.');
          return const GoogleSignInResult.error(message);
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await _supabase.auth.signInWithIdToken(
          provider: sb.OAuthProvider.google,
          idToken: idToken,
        );
        result = await _auth.signInWithCredential(credential);
      }
      final user = result.user;
      if (user == null) {
        const message = 'Google sign-in completed without a Firebase user.';
        debugPrint(message);
        return const GoogleSignInResult.error(message);
      }
      await _ensureGoogleUserDocument(user);
      await _remember(true);
      return const GoogleSignInResult.success();
    } on FirebaseAuthException catch (e) {
      _logAuthError(e);
      if (_isGoogleCancellation('${e.code} ${e.message}')) {
        return const GoogleSignInResult.cancelled();
      }
      if (_isNetworkError('${e.code} ${e.message}')) {
        return const GoogleSignInResult.error('No internet connection.');
      }
      if (_isGoogleConfigurationError('${e.code} ${e.message}')) {
        return const GoogleSignInResult.error(
          'Google sign-in is not configured correctly. Please check SHA-1, authorized domains and google-services.json.',
        );
      }
      return GoogleSignInResult.error(
        e.message ?? 'Google sign-in failed (${e.code}).',
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Google sign-in PlatformException: ${e.code} - ${e.message}; '
        'details: ${e.details}',
      );
      final diagnostic = '${e.code} ${e.message} ${e.details}';
      if (_isGoogleCancellation(diagnostic)) {
        return const GoogleSignInResult.cancelled();
      }
      if (_isGoogleConfigurationError(diagnostic)) {
        return const GoogleSignInResult.error(
          'Google sign-in is not configured correctly. Please check SHA-1, authorized domains and google-services.json.',
        );
      }
      if (_isNetworkError(diagnostic)) {
        return const GoogleSignInResult.error('No internet connection.');
      }
      return GoogleSignInResult.error(
        e.message?.trim().isNotEmpty == true
            ? e.message!
            : 'Google sign-in failed (${e.code}).',
      );
    } on GoogleSignInException catch (e) {
      final diagnostic = '$e ${e.code} ${e.description} ${e.details}';
      debugPrint('Google sign-in error: $diagnostic');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleSignInResult.cancelled();
      }
      if (_isGoogleConfigurationError(diagnostic) ||
          e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        return const GoogleSignInResult.error(
          'Google sign-in is not configured correctly. Please check SHA-1, authorized domains and google-services.json.',
        );
      }
      if (_isNetworkError(diagnostic)) {
        return const GoogleSignInResult.error('No internet connection.');
      }
      return GoogleSignInResult.error(
        e.description?.trim().isNotEmpty == true ? e.description! : diagnostic,
      );
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');
      if (_isNetworkError('${e.code} ${e.message}')) {
        return const GoogleSignInResult.error('No internet connection.');
      }
      return GoogleSignInResult.error(
        e.message?.trim().isNotEmpty == true
            ? e.message!
            : 'Firebase error (${e.code}).',
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected Google sign-in error: $e\n$stackTrace');
      final diagnostic = e.toString();
      if (_isGoogleConfigurationError(diagnostic)) {
        return const GoogleSignInResult.error(
          'Google sign-in is not configured correctly. Please check SHA-1, authorized domains and google-services.json.',
        );
      }
      if (_isNetworkError(diagnostic)) {
        return const GoogleSignInResult.error('No internet connection.');
      }
      return GoogleSignInResult.error(diagnostic);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      _logAuthError(e);
      throw _toAuthFailure(e);
    }
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String countryCode,
    String countryIso = 'IN',
    required String password,
  }) => signUpWithEmail(
    fullName,
    email,
    phoneNumber,
    countryCode,
    password,
    countryIso: countryIso,
  );

  @override
  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) => signInWithEmail(email, password, rememberMe: rememberMe);

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    if (!kIsWeb) {
      await initializeGoogleSignIn();
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
    await _remember(false);
  }

  Future<void> _remember(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_rememberKey, value);
  }

  Future<void> _updateLastLogin(User user) =>
      _firestore.collection('users').doc(user.uid).set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> _ensureGoogleUserDocument(User user) async {
    final reference = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final now = FieldValue.serverTimestamp();
      if (!snapshot.exists) {
        transaction.set(reference, {
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'createdAt': now,
        });
      }
    });
  }

  bool _isGoogleCancellation(Object diagnostic) {
    final normalized = diagnostic.toString().toLowerCase();
    return normalized.contains('popup-closed-by-user') ||
        normalized.contains('user-canceled') ||
        normalized.contains('user-cancelled') ||
        normalized.contains('user_canceled') ||
        normalized.contains('cancelled') ||
        normalized.contains('canceled') ||
        normalized.contains('sign_in_canceled');
  }

  bool _isGoogleConfigurationError(String diagnostic) {
    final normalized = diagnostic.toLowerCase();
    return normalized.contains('sign_in_failed') ||
        normalized.contains('unauthorized-domain') ||
        normalized.contains('unauthorized domain') ||
        normalized.contains('apiexception: 10') ||
        normalized.contains('apiexception 10') ||
        normalized.contains('status code: 10') ||
        normalized.contains('statuscode=10') ||
        normalized.contains('code: 10') ||
        normalized.contains('apiexception: 12500') ||
        normalized.contains('apiexception 12500') ||
        normalized.contains('status code: 12500') ||
        normalized.contains('statuscode=12500') ||
        normalized.contains('code: 12500');
  }

  bool _isNetworkError(String diagnostic) {
    final normalized = diagnostic.toLowerCase();
    return normalized.contains('network-request-failed') ||
        normalized.contains('network_error') ||
        normalized.contains('network error') ||
        normalized.contains('unavailable') ||
        normalized.contains('connection timed out') ||
        normalized.contains('socketexception') ||
        normalized.contains('apiexception: 7') ||
        normalized.contains('status code: 7') ||
        normalized.contains('no internet');
  }

  void _logAuthError(FirebaseAuthException e) =>
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

  AuthFailure _toAuthFailure(FirebaseAuthException e) {
    final message = switch (e.code) {
      'user-not-found' => 'No account was found for that email.',
      'wrong-password' => 'The password is incorrect.',
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' =>
        'This email is already registered. Try signing in instead.',
      'weak-password' =>
        'Choose a stronger password with at least 6 characters.',
      'invalid-email' => 'Enter a valid email address.',
      'network-request-failed' =>
        'Unable to connect. Check your connection and try again.',
      _ => 'Authentication failed. Please try again.',
    };
    final code = switch (e.code) {
      'email-already-in-use' => AuthFailureCode.emailAlreadyInUse,
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => AuthFailureCode.invalidCredentials,
      'network-request-failed' => AuthFailureCode.network,
      _ => AuthFailureCode.unknown,
    };
    return AuthFailure(code, message);
  }
}
