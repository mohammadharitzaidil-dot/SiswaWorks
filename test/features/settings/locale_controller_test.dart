import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:siswaworks/features/settings/data/locale_store.dart';
import 'package:siswaworks/features/settings/presentation/locale_controller.dart';

import '../../support/memory_locale_store.dart';

void main() {
  for (final code in [null, '', 'fr', 'MS', 'ms', 'en']) {
    test('loads $code with English fallback', () async {
      final controller = LocaleController(store: MemoryLocaleStore(code));
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.locale.languageCode, code == 'ms' ? 'ms' : 'en');
      expect(controller.failure, isNull);
    });
  }

  test('saves both languages and restores into a new controller', () async {
    final store = MemoryLocaleStore();
    final controller = LocaleController(store: store);
    addTearDown(controller.dispose);
    for (final code in ['ms', 'en']) {
      await controller.setLanguage(code);
      final restarted = LocaleController(store: store);
      await restarted.load();
      expect(restarted.locale.languageCode, code);
      restarted.dispose();
    }
  });

  test('failed write keeps previous language and can retry', () async {
    final store = MemoryLocaleStore()..failWrite = true;
    final controller = LocaleController(store: store);
    addTearDown(controller.dispose);
    await controller.setLanguage('ms');
    expect(controller.locale.languageCode, 'en');
    expect(controller.failure, LocaleFailure.save);
    expect(store.value, isNull);
    store.failWrite = false;
    await controller.retry();
    expect(controller.locale.languageCode, 'ms');
    expect(controller.failure, isNull);
  });

  test(
    'failed load remains usable and retry recovers saved language',
    () async {
      final store = MemoryLocaleStore('ms')..failRead = true;
      final controller = LocaleController(store: store);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.locale.languageCode, 'en');
      expect(controller.failure, LocaleFailure.load);
      store.failRead = false;
      await controller.retry();
      expect(controller.locale.languageCode, 'ms');
    },
  );

  test('rejects unsupported language without changing the store', () async {
    final store = MemoryLocaleStore();
    final controller = LocaleController(store: store);
    addTearDown(controller.dispose);
    await expectLater(controller.setLanguage('fr'), throwsArgumentError);
    expect(store.value, isNull);
  });

  test('serializes saves and does not notify after disposal', () async {
    final store = DelayedLocaleStore();
    final controller = LocaleController(store: store);
    final save = controller.setLanguage('ms');
    expect(controller.isBusy, isTrue);
    await controller.setLanguage('en');
    expect(store.writes, ['ms']);
    controller.dispose();
    store.completion.complete();
    await save;
  });
}

class DelayedLocaleStore implements LocaleStore {
  final completion = Completer<void>();
  final writes = <String>[];

  @override
  Future<String?> readLanguageCode() async => null;

  @override
  Future<void> writeLanguageCode(String languageCode) {
    writes.add(languageCode);
    return completion.future;
  }
}
