import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../../../core/widgets/app_page.dart';
import '../../../l10n/app_localizations.dart';
import 'locale_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: localeController,
    builder: (context, child) {
      final strings = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(strings.settingsTitle)),
        body: AppPage(
          children: [
            Text(
              strings.settingsLanguage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(strings.settingsLanguageDescription),
            const SizedBox(height: AppSpacing.medium),
            RadioGroup<String>(
              groupValue: localeController.locale.languageCode,
              onChanged: (code) {
                if (code != null) localeController.setLanguage(code);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'en',
                    title: Text(strings.settingsEnglish),
                    enabled: !localeController.isBusy,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'ms',
                    title: Text(strings.settingsMalay),
                    enabled: !localeController.isBusy,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (localeController.isBusy) ...[
              const SizedBox(height: AppSpacing.medium),
              LinearProgressIndicator(semanticsLabel: strings.commonLoading),
            ],
            if (localeController.failure != null) ...[
              const SizedBox(height: AppSpacing.medium),
              AppMessage(
                message: localeController.failure == LocaleFailure.load
                    ? strings.settingsLoadError
                    : strings.settingsSaveError,
                actionLabel: strings.commonRetry,
                onAction: localeController.retry,
              ),
            ],
          ],
        ),
      );
    },
  );
}
