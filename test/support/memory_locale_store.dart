import 'package:siswaworks/features/settings/data/locale_store.dart';

class MemoryLocaleStore implements LocaleStore {
  MemoryLocaleStore([this.value]);

  String? value;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<String?> readLanguageCode() async {
    if (failRead) throw StateError('Read failed');
    return value;
  }

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    if (failWrite) throw StateError('Write failed');
    value = languageCode;
  }
}
