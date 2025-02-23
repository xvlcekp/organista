import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/logger/custom_logger.dart';

const Map<String, AuthError> authErrorMapping = {
  'user-not-found': AuthErrorUserNotFound(),
  'weak-password': AuthErrorWeakPassword(),
  'invalid-email': AuthErrorInvalidEmail(),
  'operation-not-allowed': AuthErrorOperationNotAllowed(),
  'email-already-in-use': AuthErrorEmailAlreadyInUse(),
  'requires-recent-login': AuthErrorRequiresRecentLogin(),
  'no-current-user': AuthErrorNoCurrentUser(),
  'user-disabled': AuthErrorUserDisabled(),
  'invalid-credential': AuthErrorInvalidCredential(),
};

// TODO: fix [firebase_auth/quota-exceeded] Exceeded quota for verifying passwords.

@immutable
abstract class AuthError {
  final String dialogTitle;
  final String dialogText;

  const AuthError({
    required this.dialogTitle,
    required this.dialogText,
  });

  factory AuthError.from(FirebaseAuthException exception) {
    return authErrorMapping[exception.code.toLowerCase().trim()] ?? AuthErrorUnknown(exception: exception);
  }
}

@immutable
class AuthErrorUnknown extends AuthError {
  final FirebaseAuthException exception;
  AuthErrorUnknown({required this.exception})
      : super(
          dialogTitle: 'Authentication error',
          dialogText: exception.message ?? 'Unknown error',
        ) {
    CustomLogger.instance.e(exception);
  }
}

// auth/no-current-user

@immutable
class AuthErrorNoCurrentUser extends AuthError {
  const AuthErrorNoCurrentUser()
      : super(
          dialogTitle: 'No current user!',
          dialogText: 'No current user with this information was found!',
        );
}

// auth/requires-recent-login

@immutable
class AuthErrorRequiresRecentLogin extends AuthError {
  const AuthErrorRequiresRecentLogin()
      : super(
          dialogTitle: 'Requires recent login',
          dialogText: 'You need to log out and log back in again in order to perform this operation',
        );
}

// auth/operation-not-allowed

@immutable
class AuthErrorOperationNotAllowed extends AuthError {
  const AuthErrorOperationNotAllowed()
      : super(
          dialogTitle: 'Operation not allowed',
          dialogText: 'You cannot register using this method at this moment!',
        );
}

// auth/user-not-found

@immutable
class AuthErrorUserNotFound extends AuthError {
  const AuthErrorUserNotFound()
      : super(
          dialogTitle: 'User not found',
          dialogText: 'The given user was not found on the server!',
        );
}

// auth/weak-password

@immutable
class AuthErrorWeakPassword extends AuthError {
  const AuthErrorWeakPassword()
      : super(
          dialogTitle: 'Weak password',
          dialogText: 'Please choose a stronger password consisting of more characters!',
        );
}

// auth/invalid-email

@immutable
class AuthErrorInvalidEmail extends AuthError {
  const AuthErrorInvalidEmail()
      : super(
          dialogTitle: 'Invalid email',
          dialogText: 'Please double check your email and try again!',
        );
}

// auth/email-already-in-use

@immutable
class AuthErrorEmailAlreadyInUse extends AuthError {
  const AuthErrorEmailAlreadyInUse()
      : super(
          dialogTitle: 'Email already in use',
          dialogText: 'Please choose another email to register with!',
        );
}

@immutable
class AuthErrorUserDisabled extends AuthError {
  const AuthErrorUserDisabled()
      : super(
          dialogTitle: 'User is disabled',
          dialogText: 'This user has been disabled. Please contact support for help.',
        );
}

@immutable
class AuthErrorInvalidCredential extends AuthError {
  const AuthErrorInvalidCredential()
      : super(
          dialogTitle: 'Credential is invalid',
          dialogText: 'The supplied auth credential is incorrect, malformed or has expired.',
        );
}
