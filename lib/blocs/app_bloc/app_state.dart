import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/auth/auth_error.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

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
  final Iterable<MusicSheet> musicSheets;
  const AppStateLoggedIn({
    required super.isLoading,
    required this.user,
    required this.musicSheets,
    super.authError,
  });

  @override
  String toString() => 'AppStateLoggedIn, images.length = ${musicSheets.length}';

  @override
  List<Object?> get props => [isLoading, user.uid, musicSheets];
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

extension GetImages on AppState {
  Iterable<MusicSheet>? get musicSheets {
    final cls = this;
    if (cls is AppStateLoggedIn) {
      return cls.musicSheets;
    } else {
      return null;
    }
  }
}
