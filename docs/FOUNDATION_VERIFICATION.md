# Foundation verification — 2 November 2026

Tested by: Codex for Developer A. Standards: v1.0. Base commit: `9decc0e`.
Results apply to the uncommitted foundation changes in this working tree.

Environment: Flutter 3.47.5 stable, Dart 3.13.4, Windows host; Android 15/API 35
emulator `emulator-5554`, x86_64, 1080x1920. Existing Firebase project/configuration
and Android identity were used. No application data was cleared.

| Check | Result | Evidence |
|---|---|---|
| Dependency resolution | PASS | `flutter pub get --offline`; existing Firebase locked versions unchanged |
| Localization generation | PASS | `flutter gen-l10n`; en/ms generated from matching ARB catalogs |
| Formatting | PASS | 19 Dart files checked, zero changes |
| Static analysis | PASS | `flutter analyze`: no issues |
| Unit/widget tests | PASS | `flutter test`: 16 tests passed |
| Android debug build | PASS | `flutter build apk --debug`; `build/app/outputs/flutter-apk/app-debug.apk` |
| Android installation/startup | PASS | `adb install -r`: Success; cold start of `.MainActivity`: Status ok |
| First use without saved locale | PASS | No shared-preferences DataStore existed before install; English welcome and selected English radio observed |
| English on a Malay phone | PASS (widget) | Platform locale overridden to ms; app starts in en; emulator OS locale was not changed |
| Settings → Bahasa Melayu | PASS (Android) | Tetapan/Bahasa/Kembali observed; Bahasa Melayu radio checked |
| Malay after process restart | PASS (Android) | `am force-stop`, then `am start -W`; welcome remains Malay |
| Switch back to English and restart | PASS (Android) | Changed through Settings, force-stopped/relaunched; English welcome observed |
| Small screen / large text | PASS (widget) | Both locales, 320x568 at 200% text; welcome and Settings have no framework overflow |
| Visual consistency | PASS | English welcome and Malay Settings screenshots inspected |

Tests cover missing/invalid saved values, both supported values, controller
recreation, failed reads/writes and retry, rejection of unsupported codes,
concurrent writes, disposal during an outstanding write, catalog parity, route
localization, navigation back, and text scaling. Native disk persistence is
supported separately by the Android process-restart checks above.

Initial checks found a constructor lint and a test helper that searched for the
English Back tooltip after switching to Malay. Both were corrected; final checks
above passed. No outstanding failed check remains in this task.

Build warnings: Gradle emitted a Java native-access warning, and Flutter reported
future built-in Kotlin compatibility work for existing firebase_auth/firebase_core
plugins. Build succeeded; those dependency versions were not upgraded.

Not run: Firebase Auth login, Firestore reads/writes, direct unauthorized operations,
rules emulator tests, release build/signing, physical Android device, OS reboot,
web/Windows startup. Debug startup does not prove permissions or feature access.
Storage-failure scenarios were injected in tests, not induced on the Android disk.

## Screenshots

- [English welcome](verification/welcome-en.png)
- [Malay Settings](verification/settings-ms.png)
- [Malay welcome after process restart](verification/welcome-ms-restarted.png)

The emulator is left on the English welcome screen. No commit, push, merge,
Firebase setup change, rules deployment, or account operation was performed.
