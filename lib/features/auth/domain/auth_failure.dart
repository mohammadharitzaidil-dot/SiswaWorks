enum AuthFailureCode {
  invalidCredentials,
  disabled,
  tooManyRequests,
  network,
  unavailable,
  unknown,
  weakPassword,
  emailInUse,
  cancelled,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;
}
