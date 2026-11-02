import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocaleStore {
  Future<String?> readLanguageCode();
  Future<void> writeLanguageCode(String languageCode);
}

class SharedPreferencesLocaleStore implements LocaleStore {
  SharedPreferencesLocaleStore(this._preferences);

  static const languageCodeKey = 'settings.language_code';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readLanguageCode() async {
    // Reading as Object also lets a corrupt/non-string preference fall back.
    final values = await _preferences.getAll(allowList: {languageCodeKey});
    final value = values[languageCodeKey];
    return value is String ? value : null;
  }

  @override
  Future<void> writeLanguageCode(String languageCode) =>
      _preferences.setString(languageCodeKey, languageCode);
}
