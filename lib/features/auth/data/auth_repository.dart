import '../domain/auth_session.dart';

abstract interface class AuthRepository {
  /// Emits the restored session first, then sign-in/sign-out changes.
  /// Errors are AuthFailure; an error must never become a fake session.
  Stream<AuthSession?> watchSession();

  /// Authenticates an existing account; never creates an account or profile.
  /// Session changes are delivered by watchSession. Throws AuthFailure on error.
  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required String accountType,
  });
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);

  /// Ends this device's Firebase session. Throws AuthFailure on error.
  Future<void> signOut();
}
