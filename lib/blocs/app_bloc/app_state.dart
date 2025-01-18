part of 'app_bloc.dart';

@immutable
abstract class AppState {
  final bool isLoading;
  final AuthError? authError;

  const AppState({
    required this.isLoading,
    this.authError,
  });
}

@immutable
class AppStateLoggedIn extends AppState with EquatableMixin {
  final User user;
  const AppStateLoggedIn({
    required super.isLoading,
    required this.user,
    super.authError,
  });

  @override
  String toString() => 'AppStateLoggedIn';

  @override
  List<Object?> get props => [isLoading, user.uid];
}

@immutable
class AppStateLoggedOut extends AppState {
  const AppStateLoggedOut({
    required super.isLoading,
    super.authError,
  });

  @override
  String toString() => 'AppStateLoggedOut, isLoading = $isLoading, authError = $authError';
}

@immutable
class AppStateIsInRegistrationView extends AppState {
  const AppStateIsInRegistrationView({
    required super.isLoading,
    super.authError,
  });
}

extension GetUser on AppState {
  User? get user {
    final cls = this;
    if (cls is AppStateLoggedIn) {
      return cls.user;
    } else {
      return null;
    }
  }
}

// extension GetMusicSheets on AppState {
//   Iterable<MusicSheet>? get musicSheets {
//     final cls = this;
//     if (cls is AppStateLoggedIn) {
//       return cls.musicSheets;
//     } else {
//       return null;
//     }
//   }
// }
