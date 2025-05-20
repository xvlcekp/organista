part of 'app_bloc.dart';

@immutable
abstract class AppState {
  final bool isLoading;
  final AuthError? authError;
  final bool passwordResetSent;

  const AppState({
    required this.isLoading,
    this.authError,
    this.passwordResetSent = false,
  });
}

@immutable
class AppStateLoggedIn extends AppState with EquatableMixin {
  final AuthUser user;
  const AppStateLoggedIn({
    required super.isLoading,
    required this.user,
    super.authError,
  });

  @override
  String toString() => 'AppStateLoggedIn';

  @override
  List<Object?> get props => [isLoading, user.id];
}

@immutable
class AppStateLoggedOut extends AppState {
  const AppStateLoggedOut({
    required super.isLoading,
    super.authError,
    super.passwordResetSent = false,
  });

  @override
  String toString() => 'AppStateLoggedOut, isLoading = $isLoading, authError = $authError, passwordResetSent = $passwordResetSent';
}

@immutable
class AppStateIsInRegistrationView extends AppState {
  const AppStateIsInRegistrationView({
    required super.isLoading,
    super.authError,
  });
}

extension GetUser on AppState {
  AuthUser? get user {
    final cls = this;
    if (cls is AppStateLoggedIn) {
      return cls.user;
    } else {
      return null;
    }
  }
}
