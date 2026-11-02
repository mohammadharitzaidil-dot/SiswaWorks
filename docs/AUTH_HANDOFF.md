# Email/password login — standards v1.0

Owner: Developer A. Reviewer: Developer B (UI/session/localization).
Base: main 9decc0e plus the earlier uncommitted foundation task.

## Scope and behavior

The app now opens the login form for a signed-out user. Firebase restores the
device session before deciding which screen to show; a loading state prevents
the login form from briefly appearing while restoration is in progress.
An authenticated user sees a basic Account screen with their Auth email and
Log out. Settings remains available on both screens. Language preference is
independent of auth and is not cleared on logout.

Email is trimmed and validated; passwords are required but never trimmed,
logged, or saved by app code. Existing accounts are not subjected to new-account
password length rules. Password is hidden initially, with localized visibility
controls and native autofill hints. Busy requests disable submission and fields.
Failed login retains the user's input, shows a localized error, and allows retry.
Unknown-user and wrong-password failures share the same message. Validation
messages update when language changes without clearing input.

The session stream is authoritative. A successful Future alone does not navigate
to an account. The Navigator is recreated when session identity/status changes;
old routes and form state cannot be reached with Back after logout or another
identity change. A stream failure blocks the account screen and exposes retry.

This is authentication only. It does not assign student/organiser roles, load or
create Firestore profiles, or grant any feature permissions. Firebase Auth state
is not server-side authorization. Profile onboarding, registration, role/approval
guards and rules tests remain separate work under the accepted data contract.
No fake account or fallback authentication exists in production code.

## Shared interfaces for B/C

- `bootstrap()` now returns `AppDependencies` with `localeController` and
  `authController`. MainApp requires BOTH through constructor injection. The
  caller owns their lifetime; AppDependencies provides `dispose()` for teardown.
- Canonical `AuthRepository` is `features/auth/data/auth_repository.dart`.
  `watchSession()` emits restored/current `AuthSession?` and subsequent changes;
  null means signed out. `signIn({email, password})` and `signOut()` return
  Future<void>; Firebase failures are translated into `AuthFailure`.
- `AuthSession` contains only `uid` and nullable `email` from Firebase Auth.
  Do not invent a role from email or treat this model as the Firestore profile.
- `AuthController` is a ChangeNotifier. Call `start()` once at composition;
  await the stream's loading state in UI. Exposes `status`, `session`, `isBusy`,
  `failure`, `signIn`, `signOut`, and `start` for retry. Dispose cancels listening.
- `FirebaseAuthRepository` accepts a FirebaseAuth instance. Tests inject the
  same AuthRepository interface; fakes are exclusively under `test/support/`.
- `AuthGate` replaces the welcome route. The earlier WelcomeScreen is retained
  as unused foundation source; there is no duplicate active login route.
- All new user-facing text uses `auth*` keys in both shared ARB catalogs. Run
  `flutter gen-l10n` after edits. No dependency or Firebase config change was
  needed for this task.

## Firebase setup and user verification

The user confirmed Email/Password and Google are enabled in Firebase Console.
This task implements Email/Password only. Google requires a separate app-side
integration and does not appear as an inactive or misleading button.

Use an existing Firebase Authentication test account. If none exists, create a
test user through Firebase Console → Authentication → Users → Add user; the app
does not yet have registration. Enter credentials directly into the app, not
into chat, logs or source files.

Verification checklist for the project owner:

1. Log in with an existing test account; Account shows its email.
2. Force-stop and reopen the app; a persisted Firebase session opens Account.
3. Log out; login returns and Back cannot reopen Account. Reopen the app and
   confirm it remains signed out. Language preference remains unchanged.
4. Enter an incorrect password; an error appears without claiming success.
5. Change to BM in Settings; form, validation, errors and navigation translate.

The Flutter checks and Android observations actually run by Codex are recorded in
AUTH_VERIFICATION.md. Test fakes do not prove live Firebase credentials, persistent
sessions, Google sign-in or Firestore permissions.

Official references checked during implementation:
- https://firebase.google.com/docs/auth/flutter/password-auth
- https://firebase.google.com/docs/auth/flutter/start

Firebase manages native authentication persistence. The app does not store a
password/token in shared_preferences. An auth-state stream is not a guarantee
that a remotely disabled account is detected immediately; backend rules remain
the enforcement boundary for protected data.
