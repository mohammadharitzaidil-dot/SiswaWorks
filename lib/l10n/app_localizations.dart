import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
  ];

  /// No description provided for @commonAppName.
  ///
  /// In en, this message translates to:
  /// **'SiswaWorks'**
  String get commonAppName;

  /// No description provided for @commonWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SiswaWorks'**
  String get commonWelcome;

  /// No description provided for @commonWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Your campus work companion. Choose your preferred language in Settings.'**
  String get commonWelcomeDescription;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used throughout the app. Your choice is saved on this device.'**
  String get settingsLanguageDescription;

  /// No description provided for @settingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get settingsMalay;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your saved language could not be loaded. Try again or choose a language.'**
  String get settingsLoadError;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Your language could not be saved. Please try again.'**
  String get settingsSaveError;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to SiswaWorks'**
  String get authLoginTitle;

  /// No description provided for @authLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to continue.'**
  String get authLoginDescription;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authSignIn;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in…'**
  String get authSigningIn;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authPasswordRequired;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect. Please try again.'**
  String get authInvalidCredentials;

  /// No description provided for @authAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Contact the SiswaWorks team.'**
  String get authAccountDisabled;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and try again.'**
  String get authNetworkError;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Login is currently unavailable. Please try again later.'**
  String get authUnavailable;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authUnknownError;

  /// No description provided for @authRestoringSession.
  ///
  /// In en, this message translates to:
  /// **'Checking your session'**
  String get authRestoringSession;

  /// No description provided for @authSessionError.
  ///
  /// In en, this message translates to:
  /// **'Your session could not be loaded. Please try again.'**
  String get authSessionError;

  /// No description provided for @authAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get authAccountTitle;

  /// No description provided for @authSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You’re logged in'**
  String get authSignedIn;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get authSignOut;

  /// No description provided for @authSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out…'**
  String get authSigningOut;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
