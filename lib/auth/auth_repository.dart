enum AuthFailureCode {
  configurationMissing,
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
    required String password,
  });

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset({required String email});
}

class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  AuthFailure get _missingConfiguration => const AuthFailure(
    AuthFailureCode.configurationMissing,
    'Authentication is not configured. Connect an auth provider before continuing.',
  );

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    throw _missingConfiguration;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    throw _missingConfiguration;
  }

  @override
  Future<void> signInWithGoogle() async {
    throw _missingConfiguration;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    throw _missingConfiguration;
  }
}
