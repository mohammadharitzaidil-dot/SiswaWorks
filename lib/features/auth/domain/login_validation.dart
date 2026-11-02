enum LoginFieldError { required, invalidEmail }

abstract final class LoginValidation {
  static LoginFieldError? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return LoginFieldError.required;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return LoginFieldError.invalidEmail;
    }
    return null;
  }

  // Do not trim passwords or impose registration rules on existing accounts.
  static LoginFieldError? password(String value) =>
      value.isEmpty ? LoginFieldError.required : null;
}
