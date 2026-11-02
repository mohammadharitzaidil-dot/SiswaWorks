// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get commonAppName => 'SiswaWorks';

  @override
  String get commonWelcome => 'Selamat datang ke SiswaWorks';

  @override
  String get commonWelcomeDescription =>
      'Teman kerja kampus anda. Pilih bahasa pilihan anda dalam Tetapan.';

  @override
  String get commonRetry => 'Cuba lagi';

  @override
  String get commonLoading => 'Sedang memuatkan';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLanguageDescription =>
      'Pilih bahasa yang digunakan dalam aplikasi. Pilihan anda disimpan pada peranti ini.';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsMalay => 'Bahasa Melayu';

  @override
  String get settingsLoadError =>
      'Pilihan bahasa anda tidak dapat dimuatkan. Cuba lagi atau pilih bahasa.';

  @override
  String get settingsSaveError =>
      'Pilihan bahasa anda tidak dapat disimpan. Sila cuba lagi.';

  @override
  String get authLoginTitle => 'Log masuk ke SiswaWorks';

  @override
  String get authLoginDescription =>
      'Masukkan e-mel dan kata laluan anda untuk meneruskan.';

  @override
  String get authEmail => 'E-mel';

  @override
  String get authPassword => 'Kata laluan';

  @override
  String get authSignIn => 'Log masuk';

  @override
  String get authSigningIn => 'Sedang log masuk…';

  @override
  String get authShowPassword => 'Tunjukkan kata laluan';

  @override
  String get authHidePassword => 'Sembunyikan kata laluan';

  @override
  String get authEmailRequired => 'Masukkan e-mel anda.';

  @override
  String get authEmailInvalid => 'Masukkan alamat e-mel yang sah.';

  @override
  String get authPasswordRequired => 'Masukkan kata laluan anda.';

  @override
  String get authInvalidCredentials =>
      'E-mel atau kata laluan tidak betul. Sila cuba lagi.';

  @override
  String get authAccountDisabled =>
      'Akaun ini telah dinyahaktifkan. Hubungi pasukan SiswaWorks.';

  @override
  String get authTooManyRequests =>
      'Terlalu banyak percubaan. Sila tunggu dan cuba lagi.';

  @override
  String get authNetworkError =>
      'Tidak dapat disambungkan. Semak sambungan anda dan cuba lagi.';

  @override
  String get authUnavailable =>
      'Log masuk tidak tersedia buat masa ini. Sila cuba lagi kemudian.';

  @override
  String get authUnknownError => 'Sesuatu tidak kena. Sila cuba lagi.';

  @override
  String get authRestoringSession => 'Sedang menyemak sesi anda';

  @override
  String get authSessionError =>
      'Sesi anda tidak dapat dimuatkan. Sila cuba lagi.';

  @override
  String get authAccountTitle => 'Akaun';

  @override
  String get authSignedIn => 'Anda telah log masuk';

  @override
  String get authSignOut => 'Log keluar';

  @override
  String get authSigningOut => 'Sedang log keluar…';
}
