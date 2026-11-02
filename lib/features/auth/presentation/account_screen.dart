import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/locale_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/auth_session.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';

/// Basic session page. No role, approval, profile or Firestore access is implied.
class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    required this.session,
    required this.authController,
    required this.localeController,
  });

  final AuthSession session;
  final AuthController authController;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: authController,
    builder: (context, child) {
      final strings = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(strings.authAccountTitle)),
        body: AppPage(
          children: [
            Text(
              strings.authSignedIn,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (session.email != null) ...[
              const SizedBox(height: AppSpacing.medium),
              Text(
                strings.authEmail,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SelectableText(session.email!),
            ],
            const SizedBox(height: AppSpacing.large),
            AppPrimaryButton(
              label: authController.isBusy
                  ? strings.authSigningOut
                  : strings.authSignOut,
              onPressed: authController.isBusy ? null : authController.signOut,
            ),
            if (authController.failure != null) ...[
              const SizedBox(height: AppSpacing.medium),
              AppMessage(
                message: authErrorMessage(strings, authController.failure!),
              ),
            ],
            const SizedBox(height: AppSpacing.medium),
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(localeController: localeController),
                ),
              ),
              child: Text(strings.settingsTitle),
            ),
          ],
        ),
      );
    },
  );
}
