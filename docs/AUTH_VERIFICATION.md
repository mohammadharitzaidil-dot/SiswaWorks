> Historical login-only record. See [AUTH_FLOW_UPDATE.md](AUTH_FLOW_UPDATE.md) for the current authentication and first-use language flow.

# Email/password login verification — 2 November 2026

Tester: Codex for Developer A. Standards v1.0. Base commit `9decc0e` plus
uncommitted foundation and login changes; no commit/push was performed.

Environment: Flutter 3.47.5 stable, Dart 3.13.4, Windows host; Android 15/API 35
x86_64 emulator `emulator-5554`, 1080x1920. Existing Firebase configuration used.
The project owner confirmed Email/Password and Google are enabled in Console.
No Firebase provider, rules, account, database or billing configuration was changed.

| Check | Result | Evidence / boundary |
|---|---|---|
| ARB generation | PASS | `flutter gen-l10n`; both catalogs include auth messages |
| Formatting | PASS | 34 Dart files; zero pending formatting changes |
| Static analysis | PASS | `flutter analyze`: No issues found |
| Unit/widget tests | PASS | `flutter test`: all 34 tests passed (16 foundation + 18 auth) |
| Android debug build | PASS | `flutter build apk --debug` produced app-debug.apk |
| Install and cold startup | PASS | `adb install -r`: Success; `.MainActivity`: Status ok; login form displayed |
| Live invalid-credential response | PASS | One request using reserved-domain `login-check@example.invalid`; app displayed the localized incorrect-email/password error and remained signed out |
| Language change on login | PASS | Settings changed login and existing Firebase failure message to Malay |
| Language after process restart | PASS | Force-stop/start displayed Malay login; English restored afterward |
| Visual review | PASS | English and Malay login screenshots inspected |
| Successful login with a real project account | NOT RUN | No real account credentials used; owner enters them directly in app |
| Native persisted signed-in session after restart | NOT RUN | Requires successful project-account login; simulated restoration covered by tests |
| Logout against a live signed-in session | NOT RUN | Controller/root behavior covered with fake repository, not a live account |
| Google sign-in | NOT IMPLEMENTED / NOT RUN | Provider enabled in Console does not implement the Flutter flow |
| Registration/profile/roles/Firestore permissions | NOT IMPLEMENTED / NOT RUN | No profile or role data accessed; no permission claims |

Auth tests cover delayed session restoration, email normalization without password
trimming, validation, duplicate-submit protection, login retry after network
failure, failed logout, stream failure/retry, disposal during requests, credential
error mapping, password visibility, clearing old routes on session changes,
localized failures, preserving inputs and translated field errors across locale
changes, and both languages at 320x568 with 200% text and a keyboard inset.
The test titled session expiry injects a signed-out event; it is not evidence of
live Firebase token expiry or immediate disabled-user detection.

An initial widget test found cached validation text did not change language.
The form now revalidates after localized validators rebuild; final full suite
passed. During Android automation, Back initially returned to the launcher and
the keyboard later obscured the error message. The app was reopened and the
keyboard closed; observed assertions then passed. No app crash was observed.

Build emitted the same Java native-access and existing Firebase Kotlin Gradle
plugin compatibility warnings as foundation. Build succeeded; dependencies and
Firebase configuration were not changed.

## Evidence

- [English login](verification/auth/login-en.png)
- [Live invalid-credential message, English](verification/auth/login-invalid-en.png)
- [Same message translated to Malay](verification/auth/login-invalid-ms.png)
- [Malay login after restart](verification/auth/login-ms.png)

The test address is intentionally invalid and was not registered. Screenshots
contain no real credentials. The emulator was left signed out, with empty fields,
English selected and no keyboard open. Application data was not cleared.

Use the owner checklist in [AUTH_HANDOFF.md](AUTH_HANDOFF.md) to verify a real
account, native session persistence, and logout. These live checks remain pending.
