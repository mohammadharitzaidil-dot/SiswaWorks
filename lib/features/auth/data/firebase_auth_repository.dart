import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_session.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AuthSession?> watchSession() async* {
    try {
      await for (final user in _auth.authStateChanges()) {
        yield user == null
            ? null
            : AuthSession(uid: user.uid, email: user.email);
      }
    } on FirebaseAuthException catch (error) {
      throw failureForCode(error.code);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw failureForCode(error.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw failureForCode(error.code);
    }
  }

  /// Never display raw server messages or reveal whether an email is registered.
  static AuthFailure failureForCode(String code) => AuthFailure(switch (code) {
    'invalid-credential' ||
    'invalid-login-credentials' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' => AuthFailureCode.invalidCredentials,
    'user-disabled' => AuthFailureCode.disabled,
    'too-many-requests' => AuthFailureCode.tooManyRequests,
    'network-request-failed' => AuthFailureCode.network,
    'operation-not-allowed' ||
    'configuration-not-found' => AuthFailureCode.unavailable,
    _ => AuthFailureCode.unknown,
  });
}
