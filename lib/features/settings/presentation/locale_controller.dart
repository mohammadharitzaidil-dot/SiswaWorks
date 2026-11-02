import 'package:flutter/widgets.dart';

import '../data/locale_store.dart';

enum LocaleFailure { load, save }

class LocaleController extends ChangeNotifier {
  LocaleController({required this._store});

  final LocaleStore _store;
  Locale _locale = const Locale('en');
  bool _needsLanguageChoice = true;
  bool get needsLanguageChoice => _needsLanguageChoice;
  bool _isBusy = false;
  bool _disposed = false;
  LocaleFailure? _failure;
  String? _pendingLanguageCode;

  Locale get locale => _locale;
  bool get isBusy => _isBusy;
  LocaleFailure? get failure => _failure;

  Future<void> load() async {
    if (_isBusy || _disposed) return;
    _isBusy = true;
    _failure = null;
    notifyListeners();
    try {
      final code = await _store.readLanguageCode();
      if (!_disposed) {
        _locale = Locale(code == 'ms' ? 'ms' : 'en');
        _needsLanguageChoice = code != 'en' && code != 'ms';
      }
    } catch (_) {
      if (!_disposed) _failure = LocaleFailure.load;
    } finally {
      _finish();
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'ms') {
      throw ArgumentError.value(code, 'code', 'Unsupported language');
    }
    if (_isBusy || _disposed) return;
    _isBusy = true;
    _failure = null;
    _pendingLanguageCode = code;
    notifyListeners();
    try {
      await _store.writeLanguageCode(code);
      if (!_disposed) {
        _locale = Locale(code);
        _needsLanguageChoice = false;
        _pendingLanguageCode = null;
      }
    } catch (_) {
      if (!_disposed) _failure = LocaleFailure.save;
    } finally {
      _finish();
    }
  }

  Future<void> retry() async {
    if (_failure == LocaleFailure.load) {
      await load();
    } else if (_failure == LocaleFailure.save && _pendingLanguageCode != null) {
      await setLanguage(_pendingLanguageCode!);
    }
  }

  void _finish() {
    if (_disposed) return;
    _isBusy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
