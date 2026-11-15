import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/services/auth/auth_error.dart';

Future<void> showAuthError({
  required AuthError authError,
  required BuildContext context,
}) {
  final message = getLocalizedMessage(authError, context);

  return showErrorDialog(context: context, text: message);
}

String getLocalizedMessage(AuthError authError, BuildContext context) {
  final loc = context.loc;

  return switch (authError) {
    AuthGenericException() => loc.authGenericExceptionText,
    AuthErrorUserNotLoggedIn() => loc.authErrorUserNotLoggedInText,
    AuthErrorRequiresRecentLogin() => loc.authErrorRequiresRecentLoginText,
    AuthErrorOperationNotAllowed() => loc.authErrorOperationNotAllowedText,
    AuthErrorUserNotFound() => loc.authErrorUserNotFoundText,
    AuthErrorWeakPassword() => loc.authErrorWeakPasswordText,
    AuthErrorInvalidEmail() => loc.authErrorInvalidEmailText,
    AuthErrorEmailAlreadyInUse() => loc.authErrorEmailAlreadyInUseText,
    AuthErrorUserDisabled() => loc.authErrorUserDisabledText,
    AuthErrorInvalidCredential() => loc.authErrorInvalidCredentialText,
    AuthErrorGoogleSignInFailed() => loc.authErrorGoogleSignInFailedText,
    AuthErrorAppleSignInFailed() => loc.authErrorAppleSignInFailedText,
    AuthErrorNetworkRequestFailed() => loc.authErrorNetworkRequestFailedText,
    // A cancellation never reaches the dialog: the bloc turns it into a plain logged-out state.
    AuthErrorUnknown() || AuthErrorSignInCanceled() => loc.errorUnknownText,
  };
}
