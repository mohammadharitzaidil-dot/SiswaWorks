import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_session.dart';
import '../domain/login_validation.dart';

enum AuthStatus { loading, signedOut, signedIn, failed }

class AuthController extends ChangeNotifier {
  AuthController({required this.repository});

  final AuthRepository repository;
  StreamSubscription<AuthSession?>? _subscription;
  AuthStatus _status = AuthStatus.loading;
  AuthSession? _session;
  AuthFailureCode? _failure;
  bool _isBusy = false;
  bool _disposed = false;
  int _generation = 0;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  AuthFailureCode? get failure => _failure;
  bool get isBusy => _isBusy;

  Future<void> start() async {
    if (_disposed) return;
    final generation = ++_generation;
    _status = AuthStatus.loading;
    _session = null;
    _failure = null;
    _isBusy = false;
    notifyListeners();
    try {
      await _subscription?.cancel();
      if (_disposed || generation != _generation) return;
      _subscription = repository.watchSession().listen(
        (session) {
          if (_disposed || generation != _generation) return;
          _session = session;
          _status = session == null
              ? AuthStatus.signedOut
              : AuthStatus.signedIn;
          _failure = null;
          notifyListeners();
        },
        onError: (Object error) => _sessionFailed(error, generation),
        onDone: () {
          if (_status != AuthStatus.failed) {
            _sessionFailed(
              const AuthFailure(AuthFailureCode.unknown),
              generation,
            );
          }
        },
      );
    } catch (error) {
      _sessionFailed(error, generation);
    }
  }

  void _sessionFailed(Object error, int generation) {
    if (_disposed || generation != _generation) return;
    _session = null;
    _status = AuthStatus.failed;
    _failure = _code(error);
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    if (_status != AuthStatus.signedOut ||
        LoginValidation.email(email) != null ||
        LoginValidation.password(password) != null) {
      return;
    }
    await _perform(
      () => repository.signIn(email: email.trim(), password: password),
    );
  }

  void clearFailure() {
    if (_disposed || _isBusy) return;
    _failure = null;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String accountType,
  }) async {
    if (_status != AuthStatus.signedOut ||
        LoginValidation.email(email) != null ||
        password.length < 6) {
      return;
    }
    await _perform(
      () => repository.signUp(
        email: email.trim(),
        password: password,
        accountType: accountType,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    if (_status != AuthStatus.signedOut) return;
    await _perform(repository.signInWithGoogle);
  }

  Future<bool> sendPasswordReset(String email) async {
    if (_status != AuthStatus.signedOut ||
        LoginValidation.email(email) != null) {
      return false;
    }
    return _perform(() => repository.sendPasswordReset(email.trim()));
  }

  Future<void> signOut() async {
    if (_status != AuthStatus.signedIn) return;
    await _perform(repository.signOut);
  }

  Future<bool> _perform(Future<void> Function() operation) async {
    if (_disposed || _isBusy) return false;
    final generation = _generation;
    _isBusy = true;
    _failure = null;
    notifyListeners();
    try {
      await operation();
      // Session events alone open the authenticated route.
      return !_disposed && generation == _generation;
    } catch (error) {
      if (!_disposed &&
          generation == _generation &&
          _code(error) != AuthFailureCode.cancelled) {
        _failure = _code(error);
      }
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        _isBusy = false;
        notifyListeners();
      }
    }
  }

  AuthFailureCode _code(Object error) =>
      error is AuthFailure ? error.code : AuthFailureCode.unknown;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
