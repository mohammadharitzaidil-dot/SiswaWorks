enum AuthFailureCode {
  invalidCredentials,
  disabled,
  tooManyRequests,
  network,
  unavailable,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;
}
