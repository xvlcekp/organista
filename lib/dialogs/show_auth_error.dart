import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';
import 'package:organista/services/auth/auth_error.dart';

Future<void> showAuthError({
  required AuthError authError,
  required BuildContext context,
}) {
  final message = getLocalizedMessage(authError, context);

  return showErrorDialog(context, message);
}

String getLocalizedMessage(AuthError authError, BuildContext context) {
  final loc = context.loc;

  if (authError is AuthGenericException) {
    return loc.authGenericExceptionText;
  } else if (authError is AuthErrorUserNotLoggedIn) {
    return loc.authErrorUserNotLoggedInText;
  } else if (authError is AuthErrorRequiresRecentLogin) {
    return loc.authErrorRequiresRecentLoginText;
  } else if (authError is AuthErrorOperationNotAllowed) {
    return loc.authErrorOperationNotAllowedText;
  } else if (authError is AuthErrorUserNotFound) {
    return loc.authErrorUserNotFoundText;
  } else if (authError is AuthErrorWeakPassword) {
    return loc.authErrorWeakPasswordText;
  } else if (authError is AuthErrorInvalidEmail) {
    return loc.authErrorInvalidEmailText;
  } else if (authError is AuthErrorEmailAlreadyInUse) {
    return loc.authErrorEmailAlreadyInUseText;
  } else if (authError is AuthErrorUserDisabled) {
    return loc.authErrorUserDisabledText;
  } else if (authError is AuthErrorInvalidCredential) {
    return loc.authErrorInvalidCredentialText;
  } else if (authError is AuthErrorGoogleSignInFailed) {
    return loc.authErrorGoogleSignInFailedText;
  }

  return loc.errorUnknownText;
}
