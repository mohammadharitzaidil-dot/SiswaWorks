import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siswaworks/app/main_app.dart';
import 'package:siswaworks/features/settings/presentation/locale_controller.dart';

import 'support/memory_locale_store.dart';
import 'support/fake_auth_repository.dart';

import 'package:siswaworks/features/auth/domain/auth_session.dart';
import 'package:siswaworks/features/auth/presentation/auth_controller.dart';

Future<MainApp> app(LocaleController locale, {bool signedIn = true}) async {
  final repository = FakeAuthRepository(
    current: signedIn
        ? const AuthSession(uid: 'test', email: 'test@example.com')
        : null,
  );
  final auth = AuthController(repository: repository);
  addTearDown(() async {
    auth.dispose();
    await repository.dispose();
  });
  await auth.start();
  return MainApp(localeController: locale, authController: auth);
}

void main() {
  testWidgets(
    'first-use popup saves language and stays dismissed after restart and logout',
    (tester) async {
      final store = MemoryLocaleStore();
      final locale = LocaleController(store: store);
      addTearDown(locale.dispose);
      await locale.load();
      await tester.pumpWidget(await app(locale, signedIn: false));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Bahasa Melayu'));
      await tester.pumpAndSettle();
      expect(store.value, 'ms');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Tetapan'), findsNothing);
      expect(find.text('Log masuk ke SiswaWorks'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final restarted = LocaleController(store: store);
      addTearDown(restarted.dispose);
      await restarted.load();
      await tester.pumpWidget(await app(restarted));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Tetapan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Settings'), findsNothing);
      expect(find.text('Log in to SiswaWorks'), findsOneWidget);
    },
  );

  testWidgets(
    'first-use popup stays open when saving fails and supports retry',
    (tester) async {
      final store = MemoryLocaleStore()..failWrite = true;
      final locale = LocaleController(store: store);
      addTearDown(locale.dispose);
      await locale.load();
      await tester.pumpWidget(await app(locale, signedIn: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(locale.needsLanguageChoice, isTrue);
      store.failWrite = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(store.value, 'en');
    },
  );

  testWidgets(
    'save failure shows a translated retry and retains the selection',
    (tester) async {
      final store = MemoryLocaleStore('ms')..failWrite = true;
      final controller = LocaleController(store: store);
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pumpWidget(await app(controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tetapan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pilihan bahasa anda tidak dapat disimpan. Sila cuba lagi.'),
        findsOneWidget,
      );
      expect(controller.locale.languageCode, 'ms');
      store.failWrite = false;
      await tester.tap(find.text('Cuba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final code in ['en', 'ms']) {
    testWidgets('$code screens fit a narrow display with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final controller = LocaleController(store: MemoryLocaleStore(code));
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pumpWidget(await app(controller));
      await tester.pumpAndSettle();
      final settings = find.text(code == 'en' ? 'Settings' : 'Tetapan');
      await tester.ensureVisible(settings);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bahasa Melayu'));
      expect(tester.takeException(), isNull);
    });
  }
}
