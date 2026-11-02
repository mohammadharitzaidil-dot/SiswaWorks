# Authentication flow update — 2 November 2026

This supersedes the login-only scope in AUTH_HANDOFF.md and AUTH_VERIFICATION.md.

## Behaviour

- Signed-out UI offers email/password sign in, sign up with password confirmation,
  Continue with Google, and password reset. No Settings route is offered before login.
- Registration uses Firebase Authentication; it does not create Firestore profiles
  or assign student/organiser roles. The existing authenticated Account screen is
  labelled Dashboard and retains Settings and logout.
- First launch without a valid saved language displays a blocking language dialog.
  Selecting English or Malay saves the existing settings.language_code preference.
  Save failures keep the dialog open with retry. Existing preferences are honoured;
  logout does not clear the preference. Reinstall/clear app data resets first use.
- Google uses google_sign_in 7.2.0 on native platforms and Firebase popup on web.
  Cancellation stays signed out without showing a service error. Authentication
  state events, not request completion, remain the navigation authority.
- Reset requests have a generic acknowledgement to avoid revealing account existence.
  Network/service failure does not display a success acknowledgement.

## Verification

- flutter pub get: passed.
- flutter gen-l10n: passed; English/Malay catalog parity tested.
- flutter analyze: passed, no issues.
- flutter test: all 37 tests passed. Includes registration confirmation, reset
  failure/retry, Google success/cancellation through a fake repository, first-use
  persistence/retry, logout, dashboard Settings, and narrow-screen layouts.
- Live registration, actual reset-email delivery, and real Google account login
  have not been exercised. Unit/widget tests do not establish these outcomes.
- google-services.json includes a web OAuth client (type 3); no Android OAuth
  client (type 1) is present in that local file. Verify package/signing SHA in
  Firebase/Google Cloud if real Android Google sign-in fails. No console changes
  were made. Existing Firebase configuration and application ID were preserved.

References: [Firebase Google authentication](https://firebase.google.com/docs/auth/flutter/federated-auth)
and [Google Sign-In plugin](https://pub.dev/packages/google_sign_in).

## Android verification

- Formatting check passed: 35 Dart files, no pending changes.
- Android debug APK build passed; installed with adb install -r on emulator-5554.
- App cold-started successfully. Login, sign-up and password-reset screens were
  visually checked in Malay; no Settings button exists on signed-out screens.
- Android Back returns from sign-up/reset to login. Emulator left on login.
- Existing saved Malay preference was preserved; app data was not cleared.
  First-use dialog and persistence behaviour were exercised with widget tests.
- Existing Java/Kotlin/SDK tool warnings did not prevent the debug build.
