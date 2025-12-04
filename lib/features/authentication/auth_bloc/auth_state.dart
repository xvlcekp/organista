part of 'auth_bloc.dart';

@immutable
abstract class AuthState {
  final bool isLoading;
  final AuthError? authError;
  final bool passwordResetSent;

  const AuthState({
    required this.isLoading,
    this.authError,
    this.passwordResetSent = false,
  });
}

@immutable
class AuthStateLoggedIn extends AuthState with EquatableMixin {
  final AuthUser user;
  const AuthStateLoggedIn({
    required super.isLoading,
    required this.user,
    super.authError,
  });

  @override
  String toString() => 'AuthStateLoggedIn';

  @override
  List<Object?> get props => [isLoading, user.id];
}

@immutable
class AuthStateLoggedOut extends AuthState {
  const AuthStateLoggedOut({
    required super.isLoading,
    super.authError,
    super.passwordResetSent = false,
  });

  @override
  String toString() =>
      'AuthStateLoggedOut, isLoading = $isLoading, authError = $authError, passwordResetSent = $passwordResetSent';
}

@immutable
class AuthStateIsInRegistrationView extends AuthState {
  const AuthStateIsInRegistrationView({
    required super.isLoading,
    super.authError,
  });

  @override
  String toString() => 'AuthStateIsInRegistrationView';
}

extension GetUser on AuthState {
  AuthUser? get user {
    final cls = this;
    if (cls is AuthStateLoggedIn) {
      return cls.user;
    } else {
      return null;
    }
  }
}
