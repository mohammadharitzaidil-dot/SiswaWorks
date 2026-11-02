/// Identity from Firebase Auth only; this is not a role or approval decision.
class AuthSession {
  const AuthSession({required this.uid, required this.email});

  final String uid;
  final String? email;
}
