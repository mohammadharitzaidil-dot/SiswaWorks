import '../../../l10n/app_localizations.dart';
import '../domain/auth_failure.dart';

String authErrorMessage(AppLocalizations strings, AuthFailureCode failure) =>
    switch (failure) {
      AuthFailureCode.invalidCredentials => strings.authInvalidCredentials,
      AuthFailureCode.disabled => strings.authAccountDisabled,
      AuthFailureCode.tooManyRequests => strings.authTooManyRequests,
      AuthFailureCode.network => strings.authNetworkError,
      AuthFailureCode.unavailable => strings.authUnavailable,
      AuthFailureCode.weakPassword => strings.authWeakPassword,
      AuthFailureCode.emailInUse => strings.authEmailInUse,
      AuthFailureCode.cancelled => strings.authCancelled,
      AuthFailureCode.unknown => strings.authUnknownError,
    };
