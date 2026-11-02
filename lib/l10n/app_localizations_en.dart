// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonAppName => 'SiswaWorks';

  @override
  String get commonWelcome => 'Welcome to SiswaWorks';

  @override
  String get commonWelcomeDescription =>
      'Your campus work companion. Choose your preferred language in Settings.';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonLoading => 'Loading';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDescription =>
      'Choose the language used throughout the app. Your choice is saved on this device.';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsMalay => 'Bahasa Melayu';

  @override
  String get settingsLoadError =>
      'Your saved language could not be loaded. Try again or choose a language.';

  @override
  String get settingsSaveError =>
      'Your language could not be saved. Please try again.';

  @override
  String get authLoginTitle => 'Log in to SiswaWorks';

  @override
  String get authLoginDescription =>
      'Enter your email and password to continue.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Log in';

  @override
  String get authSigningIn => 'Logging in…';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authEmailRequired => 'Enter your email.';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authPasswordRequired => 'Enter your password.';

  @override
  String get authInvalidCredentials =>
      'The email or password is incorrect. Please try again.';

  @override
  String get authAccountDisabled =>
      'This account is disabled. Contact the SiswaWorks team.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get authNetworkError =>
      'Unable to connect. Check your connection and try again.';

  @override
  String get authUnavailable =>
      'Login is currently unavailable. Please try again later.';

  @override
  String get authUnknownError => 'Something went wrong. Please try again.';

  @override
  String get authRestoringSession => 'Checking your session';

  @override
  String get authSessionError =>
      'Your session could not be loaded. Please try again.';

  @override
  String get authAccountTitle => 'Account';

  @override
  String get authSignedIn => 'You’re logged in';

  @override
  String get authSignOut => 'Log out';

  @override
  String get authSigningOut => 'Logging out…';
}
