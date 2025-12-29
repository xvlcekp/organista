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
  'no-current-user': AuthErrorUserNotLoggedIn(),
  'user-disabled': AuthErrorUserDisabled(),
  'invalid-credential': AuthErrorInvalidCredential(),
};

@immutable
abstract class AuthError {
  const AuthError();

  factory AuthError.from(FirebaseAuthException exception) {
    return authErrorMapping[exception.code.toLowerCase().trim()] ?? AuthErrorUnknown(exception: exception);
  }
}

@immutable
class AuthErrorUnknown extends AuthError {
  final FirebaseAuthException exception;
  AuthErrorUnknown({required this.exception}) : super() {
    logger.e('Unknown auth error with exception code: ${exception.code}', error: exception);
  }
}

@immutable
class AuthGenericException extends AuthError {
  const AuthGenericException() : super();
}

// auth/no-current-user

@immutable
class AuthErrorUserNotLoggedIn extends AuthError {
  const AuthErrorUserNotLoggedIn() : super();
}

// auth/requires-recent-login

@immutable
class AuthErrorRequiresRecentLogin extends AuthError {
  const AuthErrorRequiresRecentLogin() : super();
}

// auth/operation-not-allowed

@immutable
class AuthErrorOperationNotAllowed extends AuthError {
  const AuthErrorOperationNotAllowed() : super();
}

// auth/user-not-found

@immutable
class AuthErrorUserNotFound extends AuthError {
  const AuthErrorUserNotFound() : super();
}

// auth/weak-password

@immutable
class AuthErrorWeakPassword extends AuthError {
  const AuthErrorWeakPassword() : super();
}

// auth/invalid-email

@immutable
class AuthErrorInvalidEmail extends AuthError {
  const AuthErrorInvalidEmail() : super();
}

// auth/email-already-in-use

@immutable
class AuthErrorEmailAlreadyInUse extends AuthError {
  const AuthErrorEmailAlreadyInUse() : super();
}

@immutable
class AuthErrorUserDisabled extends AuthError {
  const AuthErrorUserDisabled() : super();
}

@immutable
class AuthErrorInvalidCredential extends AuthError {
  const AuthErrorInvalidCredential() : super();
}

@immutable
class AuthErrorGoogleSignInFailed extends AuthError {
  const AuthErrorGoogleSignInFailed() : super();
}

@immutable
class AuthErrorAppleSignInFailed extends AuthError {
  const AuthErrorAppleSignInFailed() : super();
}
