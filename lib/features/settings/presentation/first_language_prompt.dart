import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'locale_controller.dart';

/// A persistent modal over every auth state until a language is saved.
class FirstLanguagePrompt extends StatelessWidget {
  const FirstLanguagePrompt({super.key, required this.controller});
  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        scrollable: true,
        title: Text(strings.settingsFirstLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.settingsFirstLanguageDescription),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: controller.isBusy
                  ? null
                  : () => controller.setLanguage('en'),
              child: Text(strings.settingsEnglish),
            ),
            OutlinedButton(
              onPressed: controller.isBusy
                  ? null
                  : () => controller.setLanguage('ms'),
              child: Text(strings.settingsMalay),
            ),
            if (controller.isBusy) const LinearProgressIndicator(),
            if (controller.failure != null) ...[
              Text(
                controller.failure == LocaleFailure.load
                    ? strings.settingsLoadError
                    : strings.settingsSaveError,
              ),
              TextButton(
                onPressed: controller.isBusy ? null : controller.retry,
                child: Text(strings.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
