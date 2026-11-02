import 'package:flutter_test/flutter_test.dart';
import 'package:siswaworks/features/auth/data/firebase_auth_repository.dart';
import 'package:siswaworks/features/auth/domain/auth_failure.dart';

void main() {
  test('credential errors do not reveal whether an account exists', () {
    for (final code in [
      'invalid-credential',
      'invalid-login-credentials',
      'wrong-password',
      'user-not-found',
      'invalid-email',
    ]) {
      expect(
        FirebaseAuthRepository.failureForCode(code).code,
        AuthFailureCode.invalidCredentials,
      );
    }
  });

  test(
    'maps supported service errors and hides unrecognized server messages',
    () {
      final cases = {
        'user-disabled': AuthFailureCode.disabled,
        'too-many-requests': AuthFailureCode.tooManyRequests,
        'network-request-failed': AuthFailureCode.network,
        'operation-not-allowed': AuthFailureCode.unavailable,
        'configuration-not-found': AuthFailureCode.unavailable,
        'unrecognized-server-detail': AuthFailureCode.unknown,
      };
      for (final entry in cases.entries) {
        expect(
          FirebaseAuthRepository.failureForCode(entry.key).code,
          entry.value,
        );
      }
    },
  );
}
