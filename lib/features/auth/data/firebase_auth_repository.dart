import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_session.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;
  FirebaseAuth get auth => _auth;
  static Future<void>? _googleInitialization;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String accountType,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await FirebaseFirestore.instanceFor(app: _auth.app)
          .collection('signup_intents')
          .doc(user.uid)
          .set({'accountType': accountType});
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw failureForCode(error.code);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      // Do not disclose whether this address belongs to an account.
      if (error.code != 'user-not-found') throw failureForCode(error.code);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        await (_googleInitialization ??= GoogleSignIn.instance.initialize());
        final account = await GoogleSignIn.instance.authenticate();
        final token = account.authentication.idToken;
        if (token == null) throw const AuthFailure(AuthFailureCode.unavailable);
        await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: token),
        );
      }
    } on GoogleSignInException catch (error) {
      throw AuthFailure(
        error.code == GoogleSignInExceptionCode.canceled
            ? AuthFailureCode.cancelled
            : AuthFailureCode.unavailable,
      );
    } on FirebaseAuthException catch (error) {
      throw failureForCode(error.code);
    }
  }

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
    'weak-password' => AuthFailureCode.weakPassword,
    'email-already-in-use' => AuthFailureCode.emailInUse,
    'popup-closed-by-user' ||
    'cancelled-popup-request' => AuthFailureCode.cancelled,
    'user-disabled' => AuthFailureCode.disabled,
    'too-many-requests' => AuthFailureCode.tooManyRequests,
    'network-request-failed' => AuthFailureCode.network,
    'operation-not-allowed' ||
    'configuration-not-found' => AuthFailureCode.unavailable,
    _ => AuthFailureCode.unknown,
  });
}
