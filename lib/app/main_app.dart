import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/settings/presentation/locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'auth_gate.dart';

/// The caller owns both controllers and disposes them when no longer needed.
class MainApp extends StatelessWidget {
  const MainApp({
    super.key,
    required this.localeController,
    required this.authController,
  });

  final LocaleController localeController;
  final AuthController authController;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([localeController, authController]),
    builder: (context, child) => MaterialApp(
      // Recreate the Navigator when identity changes so Back cannot expose
      // another session's routes. Locale changes keep the current route intact.
      key: ValueKey((authController.status, authController.session?.uid)),
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).commonAppName,
      theme: AppTheme.light,
      locale: localeController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AuthGate(
        authController: authController,
        localeController: localeController,
      ),
    ),
  );
}
