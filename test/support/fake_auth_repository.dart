import 'dart:async';

import 'package:siswaworks/features/auth/data/auth_repository.dart';
import 'package:siswaworks/features/auth/domain/auth_failure.dart';
import 'package:siswaworks/features/auth/domain/auth_session.dart';

/// Test-only fake. Production always constructs FirebaseAuthRepository.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.current});

  AuthSession? current;
  final events = StreamController<AuthSession?>.broadcast();
  Completer<void>? signInGate;
  Completer<void>? initialGate;
  AuthFailure? signInFailure;
  AuthFailure? signOutFailure;
  int signInCalls = 0;
  String? receivedEmail;
  String? receivedPassword;

  @override
  Stream<AuthSession?> watchSession() async* {
    await initialGate?.future;
    yield current;
    yield* events.stream;
  }

  void emit(AuthSession? session) {
    current = session;
    events.add(session);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    receivedEmail = email;
    receivedPassword = password;
    await signInGate?.future;
    if (signInFailure != null) throw signInFailure!;
    emit(AuthSession(uid: 'test-user', email: email));
  }

  @override
  Future<void> signOut() async {
    if (signOutFailure != null) throw signOutFailure!;
    emit(null);
  }

  Future<void> dispose() => events.close();
}
