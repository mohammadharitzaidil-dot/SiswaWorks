import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/locale_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/login_validation.dart';
import 'auth_controller.dart';
import 'auth_error_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authController,
    required this.localeController,
  });

  final AuthController authController;
  final LocaleController localeController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _submitted = false;

  Locale? _validationLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_validationLocale != locale && _submitted) {
      // FormField caches its error text. Revalidate after translated validators
      // have rebuilt, without clearing the user's input.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
    _validationLocale = locale;
  }

  void _submit() {
    if (widget.authController.isBusy) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.authController.signIn(email: _email.text, password: _password.text);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.authController,
    builder: (context, child) {
      final strings = AppLocalizations.of(context);
      final busy = widget.authController.isBusy;
      final failure = widget.authController.failure;
      return Scaffold(
        appBar: AppBar(title: Text(strings.commonAppName)),
        body: AppPage(
          children: [
            const SizedBox(height: AppSpacing.large),
            Text(
              strings.authLoginTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(strings.authLoginDescription),
            const SizedBox(height: AppSpacing.large),
            AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('login-email'),
                      controller: _email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      decoration: InputDecoration(labelText: strings.authEmail),
                      validator: (value) => switch (LoginValidation.email(
                        value ?? '',
                      )) {
                        LoginFieldError.required => strings.authEmailRequired,
                        LoginFieldError.invalidEmail =>
                          strings.authEmailInvalid,
                        null => null,
                      },
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    TextFormField(
                      key: const ValueKey('login-password'),
                      controller: _password,
                      enabled: !busy,
                      obscureText: _obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: strings.authPassword,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? strings.authShowPassword
                              : strings.authHidePassword,
                          onPressed: busy
                              ? null
                              : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          LoginValidation.password(value ?? '') == null
                          ? null
                          : strings.authPasswordRequired,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    AppPrimaryButton(
                      label: busy ? strings.authSigningIn : strings.authSignIn,
                      onPressed: busy ? null : _submit,
                    ),
                    if (busy) ...[
                      const SizedBox(height: AppSpacing.medium),
                      LinearProgressIndicator(
                        semanticsLabel: strings.authSigningIn,
                      ),
                    ],
                    if (failure != null) ...[
                      const SizedBox(height: AppSpacing.medium),
                      AppMessage(message: authErrorMessage(strings, failure)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(localeController: widget.localeController),
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
