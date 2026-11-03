import '../features/auth/data/firebase_auth_repository.dart';
import 'onboarding_gate.dart';

import 'package:flutter/material.dart';

import '../core/widgets/app_message.dart';
import '../core/widgets/app_page.dart';
import '../features/auth/presentation/account_screen.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/settings/presentation/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../features/settings/presentation/first_language_prompt.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authController,
    required this.localeController,
  });

  final AuthController authController;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (localeController.needsLanguageChoice) {
      return Scaffold(
        body: Stack(
          children: [
            const ModalBarrier(dismissible: false, color: Colors.black54),
            FirstLanguagePrompt(controller: localeController),
          ],
        ),
      );
    }
    return switch (authController.status) {
      AuthStatus.loading => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: strings.authRestoringSession,
          ),
        ),
      ),
      AuthStatus.failed => Scaffold(
        appBar: AppBar(title: Text(strings.commonAppName)),
        body: AppPage(
          children: [
            AppMessage(
              message: strings.authSessionError,
              actionLabel: strings.commonRetry,
              onAction: authController.start,
            ),
          ],
        ),
      ),
      AuthStatus.signedOut => LoginScreen(
        authController: authController,
        localeController: localeController,
      ),
      AuthStatus.signedIn
          when authController.repository is FirebaseAuthRepository =>
        OnboardingGate(
          key: ValueKey(authController.session!.uid),
          auth: (authController.repository as FirebaseAuthRepository).auth,
          uid: authController.session!.uid,
          signOut: authController.signOut,
          account: AccountScreen(
            session: authController.session!,
            authController: authController,
            localeController: localeController,
          ),
        ),
      AuthStatus.signedIn => AccountScreen(
        session: authController.session!,
        authController: authController,
        localeController: localeController,
      ),
    };
  }
}
