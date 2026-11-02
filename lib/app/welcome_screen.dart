import 'package:flutter/material.dart';

import '../core/widgets/app_message.dart';
import '../core/widgets/app_page.dart';
import '../core/widgets/app_primary_button.dart';
import '../features/settings/presentation/locale_controller.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.commonAppName)),
      body: AppPage(
        children: [
          const SizedBox(height: AppSpacing.extraLarge),
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            strings.commonWelcome,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          AppMessage(message: strings.commonWelcomeDescription),
          const SizedBox(height: AppSpacing.large),
          AppPrimaryButton(
            label: strings.settingsTitle,
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) =>
                    SettingsScreen(localeController: localeController),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
