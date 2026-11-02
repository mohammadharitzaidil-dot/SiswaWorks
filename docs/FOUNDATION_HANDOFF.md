# Foundation handoff — standards v1.0

> Follow-up: the login task replaces the welcome route and changes bootstrap/MainApp injection. See [AUTH_HANDOFF.md](AUTH_HANDOFF.md) for current interfaces. The foundation results below describe the earlier task.

Owner: Developer A. UI/localization reviewer: B. Dependencies/build reviewer: C.
Base: main at 9decc0e. This task adds only the welcome screen and Settings.

## Shared entry points

- `lib/main.dart` binds Flutter and calls `bootstrap()`; `lib/app/bootstrap.dart`
  initializes the existing Firebase configuration and loads the device locale.
- `MainApp(localeController: ...)` in `lib/app/main_app.dart` is the Firebase-free
  widget root. Its caller owns the controller. Tests inject a `LocaleStore`.
- `LocaleController({required LocaleStore store})` is a ChangeNotifier with
  `locale`, `isBusy`, `failure`, `load()`, `setLanguage(code)` and `retry()`.
  Await `load()` before mounting the app. Supported codes are `en` and `ms`.
- `LocaleStore.readLanguageCode()` and `writeLanguageCode(String)` are async.
  The production adapter uses SharedPreferencesAsync; the local key is
  `settings.language_code`. There is no Firestore field for language.
- No preference or an invalid preference means English, irrespective of the
  phone locale. A read failure uses English and exposes retry in Settings.
  A failed save retains the previous language and exposes retry. Concurrent
  changes are blocked while a request is pending. A successful save updates
  the open route and the welcome screen, without resetting Navigator.
- Navigate with Flutter `Navigator` and `MaterialPageRoute`, passing dependencies
  through constructors. There are no session/role guards until auth is built.

## UI and localization

Use `AppTheme.light`, `AppSpacing`, `AppPage`, `AppPrimaryButton`, and
`AppMessage` for the initial shared patterns. AppPage provides safe-area padding,
scrolling, and a maximum content width. Theme supplies Material 3 typography,
colors, button and input decoration. Add further shared widgets when consumed.

Use `AppLocalizations.of(context)` from `lib/l10n/app_localizations.dart`.
Add complete messages to BOTH `app_en.arb` and `app_ms.arb`, preserving the v1.0
prefix ownership. This change adds only `common*` and `settings*` keys.
Run `flutter gen-l10n`; never edit generated Dart manually. Generated Dart is
included with this handoff so imports work before the first generation.

## Dependencies

- `flutter_localizations`: Flutter SDK package, required by the accepted standard.
- `intl: ^0.20.3`: matches the installed Flutter localization SDK constraint.
- `shared_preferences: 2.5.3`: pinned existing cached release compatible with
  this SDK; BSD-3-Clause, maintained in flutter/packages. No suitable persistence
  adapter existed in the base app. Native platform files or a custom MethodChannel
  would duplicate a maintained plugin. This adds platform plugin/build dependencies;
  exact transitive versions are recorded in pubspec.lock. APK size delta has not
  been measured. It stores a non-sensitive UI preference only.
- Existing Firebase dependency constraints/configuration remain unchanged.

Official references: https://pub.dev/packages/shared_preferences/versions/2.5.3
and https://docs.flutter.dev/ui/internationalization.

## Checks

Run `flutter pub get`, `flutter gen-l10n`,
`dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`, and `flutter build apk --debug`.

Widget/unit tests cover locale fallback, English on a Malay phone, switching,
controller recreation, failures/retry, concurrent saves, disposal, catalog parity,
and both screens at 320x568 with 200% text. Memory-backed tests alone do not prove
Android disk persistence; force-stop/relaunch the installed app separately.

Android checklist: start with no language preference; verify English; Settings →
Bahasa Melayu; go back; force-stop/relaunch; verify Malay; switch to English;
force-stop/relaunch; verify English. Do not clear application data containing
someone else's test work to simulate first use.

See [FOUNDATION_VERIFICATION.md](FOUNDATION_VERIFICATION.md) for executed results and screenshots. Authentication, Firestore
reads/writes, permission enforcement, release builds, and other platform startup
are outside this task and must not be inferred from a successful debug startup.
