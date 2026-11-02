import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/locale_controller.dart';
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

enum _AuthMode { signIn, signUp, reset }

class _LoginScreenState extends State<LoginScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  _AuthMode _mode = _AuthMode.signIn;
  final _confirmation = TextEditingController();
  bool _resetSent = false;
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

  void _changeMode(_AuthMode mode) {
    if (widget.authController.isBusy) return;
    widget.authController.clearFailure();
    setState(() {
      _mode = mode;
      _formKey = GlobalKey<FormState>();
      _submitted = false;
      _resetSent = false;
      _password.clear();
      _confirmation.clear();
      _obscurePassword = true;
    });
  }

  Future<void> _submit() async {
    if (widget.authController.isBusy) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    switch (_mode) {
      case _AuthMode.signIn:
        await widget.authController.signIn(
          email: _email.text,
          password: _password.text,
        );
      case _AuthMode.signUp:
        await widget.authController.signUp(
          email: _email.text,
          password: _password.text,
        );
      case _AuthMode.reset:
        final sent = await widget.authController.sendPasswordReset(_email.text);
        if (mounted) setState(() => _resetSent = sent);
    }
  }

  @override
  void dispose() {
    _confirmation.dispose();
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
      final title = switch (_mode) {
        _AuthMode.signIn => strings.authLoginTitle,
        _AuthMode.signUp => strings.authSignUpTitle,
        _AuthMode.reset => strings.authResetTitle,
      };
      final description = switch (_mode) {
        _AuthMode.signIn => strings.authLoginDescription,
        _AuthMode.signUp => strings.authSignUpDescription,
        _AuthMode.reset => strings.authResetDescription,
      };
      final submitLabel = switch (_mode) {
        _AuthMode.signIn => strings.authSignIn,
        _AuthMode.signUp => strings.authSignUp,
        _AuthMode.reset => strings.authSendReset,
      };
      return PopScope(
        canPop: _mode == _AuthMode.signIn && !busy,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !busy) _changeMode(_AuthMode.signIn);
        },
        child: Scaffold(
          appBar: AppBar(title: Text(strings.commonAppName)),
          body: AppPage(
            children: [
              const SizedBox(height: AppSpacing.large),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.small),
              Text(description),
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
                        decoration: InputDecoration(
                          labelText: strings.authEmail,
                        ),
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
                      if (_mode != _AuthMode.reset)
                        TextFormField(
                          key: const ValueKey('login-password'),
                          controller: _password,
                          enabled: !busy,
                          obscureText: _obscurePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          autofillHints: [
                            _mode == _AuthMode.signUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
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
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (LoginValidation.password(value ?? '') != null) {
                              return strings.authPasswordRequired;
                            }
                            if (_mode == _AuthMode.signUp &&
                                value!.length < 6) {
                              return strings.authWeakPassword;
                            }
                            return null;
                          },
                        ),
                      if (_mode == _AuthMode.signUp) ...[
                        const SizedBox(height: AppSpacing.medium),
                        TextFormField(
                          key: const ValueKey('signup-confirm-password'),
                          controller: _confirmation,
                          enabled: !busy,
                          obscureText: _obscurePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: strings.authConfirmPassword,
                          ),
                          validator: (value) => value == _password.text
                              ? null
                              : strings.authPasswordMismatch,
                        ),
                      ],
                      if (_mode == _AuthMode.signIn)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => _changeMode(_AuthMode.reset),
                            child: Text(strings.authForgotPassword),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.large),
                      AppPrimaryButton(
                        label: busy
                            ? (_mode == _AuthMode.signIn
                                  ? strings.authSigningIn
                                  : strings.commonLoading)
                            : submitLabel,
                        onPressed: busy ? null : _submit,
                      ),
                      if (busy) ...[
                        const SizedBox(height: AppSpacing.medium),
                        LinearProgressIndicator(
                          semanticsLabel: strings.authSigningIn,
                        ),
                      ],
                      if (_resetSent) ...[
                        const SizedBox(height: AppSpacing.medium),
                        AppMessage(message: strings.authResetSent),
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
              if (_mode != _AuthMode.reset)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : widget.authController.signInWithGoogle,
                  child: Text(strings.authGoogle),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => _changeMode(
                        _mode == _AuthMode.signIn
                            ? _AuthMode.signUp
                            : _AuthMode.signIn,
                      ),
                child: Text(
                  _mode == _AuthMode.signIn
                      ? strings.authSignUp
                      : strings.authBackToSignIn,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
