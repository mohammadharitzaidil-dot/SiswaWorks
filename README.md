# SiswaWorks

Flutter application using development standards v1.0. The app includes email/password login, a basic authenticated Account screen, and
logout. Foundation includes the
welcome screen, shared Material 3 theme and widgets, and Settings with persistent
English/Bahasa Melayu selection. English is the first-use default, regardless of
the phone language.

## Local setup and checks

Verified with Flutter 3.47.5 stable / Dart 3.13.4. Use the existing Android and
Firebase configuration; application ID remains `com.siswaworks.app`.

```sh
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter run -d <android-device-id>
```

The root widget is `lib/app/main_app.dart`; bootstrap and dependency composition
are in `lib/app/bootstrap.dart`. B/C should read
[Foundation handoff](docs/FOUNDATION_HANDOFF.md) before integrating screens.
See [verification evidence](docs/FOUNDATION_VERIFICATION.md) for actual results
and limitations. Login now uses Firebase Auth. See [login handoff](docs/AUTH_HANDOFF.md) and [login verification](docs/AUTH_VERIFICATION.md) for the current entry points and live checks still pending. Registration, Google sign-in, profiles/role guards, timetable, jobs and applications are not implemented yet.
