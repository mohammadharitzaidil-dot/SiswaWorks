import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siswaworks/app/main_app.dart';
import 'package:siswaworks/features/auth/domain/auth_failure.dart';
import 'package:siswaworks/features/auth/domain/auth_session.dart';
import 'package:siswaworks/features/auth/presentation/auth_controller.dart';
import 'package:siswaworks/features/settings/presentation/locale_controller.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_locale_store.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    FakeAuthRepository repo, {
    String code = 'en',
  }) async {
    final locale = LocaleController(store: MemoryLocaleStore(code));
    final auth = AuthController(repository: repo);
    addTearDown(() async {
      auth.dispose();
      locale.dispose();
      await repo.dispose();
    });
    await locale.load();
    await auth.start();
    await tester.pumpWidget(
      MainApp(localeController: locale, authController: auth),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      ' test-password ',
    );
  }

  testWidgets(
    'validates fields; hides password by default and toggles visibility',
    (tester) async {
      final repo = FakeAuthRepository();
      await mount(tester, repo);
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(repo.signInCalls, 0);
      final password = find.descendant(
        of: find.byKey(const ValueKey('login-password')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
    },
  );

  testWidgets(
    'busy state blocks duplicate submissions; success and logout change root',
    (tester) async {
      final repo = FakeAuthRepository()..signInGate = Completer<void>();
      await mount(tester, repo);
      await fill(tester);
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.text('Logging in…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(repo.signInCalls, 1);
      repo.signInGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('You’re logged in'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.byKey(const ValueKey('login-password')), findsNothing);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log in to SiswaWorks'), findsOneWidget);
      final email = tester.widget<TextFormField>(
        find.byKey(const ValueKey('login-email')),
      );
      expect(email.controller!.text, isEmpty);
    },
  );

  testWidgets('Malay errors preserve input and permit retry', (tester) async {
    final repo = FakeAuthRepository()
      ..signInFailure = const AuthFailure(AuthFailureCode.invalidCredentials);
    await mount(tester, repo, code: 'ms');
    await fill(tester);
    await tester.tap(find.text('Log masuk'));
    await tester.pumpAndSettle();
    expect(
      find.text('E-mel atau kata laluan tidak betul. Sila cuba lagi.'),
      findsOneWidget,
    );
    final password = tester.widget<TextFormField>(
      find.byKey(const ValueKey('login-password')),
    );
    expect(password.controller!.text, ' test-password ');
    repo.signInFailure = null;
    await tester.tap(find.text('Log masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Anda telah log masuk'), findsOneWidget);
  });

  testWidgets('session expiry removes open routes and old account content', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      current: const AuthSession(uid: 'old-user', email: 'old@example.com'),
    );
    await mount(tester, repo);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    repo.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Log in to SiswaWorks'), findsOneWidget);
    expect(find.text('old@example.com'), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets(
    'login has no Settings and Google cancellation stays signed out',
    (tester) async {
      final repo = FakeAuthRepository()
        ..signInFailure = const AuthFailure(AuthFailureCode.cancelled);
      await mount(tester, repo);
      expect(find.text('Settings'), findsNothing);
      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(repo.googleCalls, 1);
      expect(find.text('Log in to SiswaWorks'), findsOneWidget);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsNothing,
      );
      repo.signInFailure = null;
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('google@example.com'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets(
    'sign up requires a matching confirmation before creating session',
    (tester) async {
      final repo = FakeAuthRepository();
      await mount(tester, repo);
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(repo.signUpCalls, 0);
      await tester.enterText(
        find.byKey(const ValueKey('signup-confirm-password')),
        ' test-password ',
      );
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(repo.signUpCalls, 1);
      expect(repo.receivedPassword, ' test-password ');
      expect(find.text('You’re logged in'), findsOneWidget);
    },
  );

  testWidgets(
    'reset failure does not show success; retry sends email without signing in',
    (tester) async {
      final repo = FakeAuthRepository()
        ..resetFailure = const AuthFailure(AuthFailureCode.network);
      await mount(tester, repo);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('login-password')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('login-email')),
        ' user@example.com ',
      );
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(find.textContaining('If an account uses'), findsNothing);
      expect(
        find.text('Unable to connect. Check your connection and try again.'),
        findsOneWidget,
      );
      repo.resetFailure = null;
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(repo.receivedEmail, 'user@example.com');
      expect(find.textContaining('If an account uses'), findsOneWidget);
      expect(repo.current, isNull);
      await tester.ensureVisible(find.text('Back to sign in'));
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Log in to SiswaWorks'), findsOneWidget);
    },
  );

  for (final code in ['en', 'ms']) {
    testWidgets(
      '$code login validation and keyboard fit small screen at 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 180);
        tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );
        await mount(tester, FakeAuthRepository(), code: code);
        final submit = find.text(code == 'en' ? 'Log in' : 'Log masuk');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(
            code == 'en'
                ? 'Enter your password.'
                : 'Masukkan kata laluan anda.',
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
