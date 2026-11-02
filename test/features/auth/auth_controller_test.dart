import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:siswaworks/features/auth/domain/auth_failure.dart';
import 'package:siswaworks/features/auth/domain/auth_session.dart';
import 'package:siswaworks/features/auth/presentation/auth_controller.dart';

import '../../support/fake_auth_repository.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(repository: repository);
  });

  tearDown(() async {
    controller.dispose();
    await repository.dispose();
  });

  test('waits for restored state and does not briefly display login', () async {
    repository.current = const AuthSession(
      uid: 'existing',
      email: 'test@example.com',
    );
    repository.initialGate = Completer<void>();
    await controller.start();
    expect(controller.status, AuthStatus.loading);
    repository.initialGate!.complete();
    await flush();
    expect(controller.status, AuthStatus.signedIn);
    expect(controller.session!.uid, 'existing');
  });

  test('signs in, trims only email and signs out', () async {
    await controller.start();
    await flush();
    await controller.signIn(email: ' test@example.com ', password: ' secret ');
    await flush();
    expect(repository.receivedEmail, 'test@example.com');
    expect(repository.receivedPassword, ' secret ');
    expect(controller.status, AuthStatus.signedIn);
    await controller.signOut();
    await flush();
    expect(controller.status, AuthStatus.signedOut);
    expect(controller.session, isNull);
  });

  test('invalid fields never reach the repository', () async {
    await controller.start();
    await flush();
    await controller.signIn(email: 'bad', password: 'secret');
    await controller.signIn(email: 'test@example.com', password: '');
    expect(repository.signInCalls, 0);
  });

  test(
    'duplicates are blocked; failed login keeps the user signed out',
    () async {
      repository.signInGate = Completer<void>();
      repository.signInFailure = const AuthFailure(AuthFailureCode.network);
      await controller.start();
      await flush();
      final first = controller.signIn(
        email: 'test@example.com',
        password: 'secret',
      );
      await controller.signIn(email: 'test@example.com', password: 'secret');
      expect(controller.isBusy, isTrue);
      expect(repository.signInCalls, 1);
      repository.signInGate!.complete();
      await first;
      expect(controller.failure, AuthFailureCode.network);
      expect(controller.status, AuthStatus.signedOut);
      expect(controller.isBusy, isFalse);
      repository.signInFailure = null;
      await controller.signIn(email: 'test@example.com', password: 'secret');
      await flush();
      expect(controller.status, AuthStatus.signedIn);
      expect(controller.failure, isNull);
    },
  );

  test('failed logout does not claim a signed-out session', () async {
    repository.current = const AuthSession(uid: 'existing', email: null);
    repository.signOutFailure = const AuthFailure(AuthFailureCode.network);
    await controller.start();
    await flush();
    await controller.signOut();
    expect(controller.status, AuthStatus.signedIn);
    expect(controller.failure, AuthFailureCode.network);
  });

  test(
    'stream failure blocks account content and retry restores state',
    () async {
      repository.current = const AuthSession(uid: 'existing', email: null);
      await controller.start();
      await flush();
      repository.events.addError(const AuthFailure(AuthFailureCode.network));
      await flush();
      expect(controller.status, AuthStatus.failed);
      expect(controller.session, isNull);
      await controller.start();
      await flush();
      expect(controller.status, AuthStatus.signedIn);
    },
  );

  test('pending operation cannot notify after disposal', () async {
    final repo = FakeAuthRepository()..signInGate = Completer<void>();
    final disposable = AuthController(repository: repo);
    await disposable.start();
    await flush();
    final request = disposable.signIn(
      email: 'test@example.com',
      password: 'secret',
    );
    disposable.dispose();
    repo.signInGate!.complete();
    await request;
    await repo.dispose();
  });
}
