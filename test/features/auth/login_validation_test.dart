import 'package:flutter_test/flutter_test.dart';
import 'package:siswaworks/features/auth/domain/login_validation.dart';

void main() {
  test(
    'validates required and malformed emails without a domain restriction',
    () {
      for (final email in ['', '   ']) {
        expect(LoginValidation.email(email), LoginFieldError.required);
      }
      for (final email in ['hello', 'a@@b.com', 'a b@example.com', 'a@b']) {
        expect(LoginValidation.email(email), LoginFieldError.invalidEmail);
      }
      for (final email in [
        'student@example.com',
        ' person+test@uthm.edu.my ',
      ]) {
        expect(LoginValidation.email(email), isNull);
      }
    },
  );

  test(
    'requires password without imposing new-account rules or trimming it',
    () {
      expect(LoginValidation.password(''), LoginFieldError.required);
      expect(LoginValidation.password('x'), isNull);
      expect(LoginValidation.password(' x '), isNull);
    },
  );
}
