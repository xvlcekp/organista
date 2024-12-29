import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/auth/auth_error.dart';

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
  final Iterable<Reference> images;
  final Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> imagesData;
  const AppStateLoggedIn({
    required super.isLoading,
    required this.user,
    required this.images,
    required this.imagesData,
    super.authError,
  });

  @override
  String toString() => 'AppStateLoggedIn, images.length = ${images.length}';

  @override
  List<Object?> get props => [isLoading, user.uid, images.length];
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
  Iterable<Reference>? get images {
    final cls = this;
    if (cls is AppStateLoggedIn) {
      return cls.images;
    } else {
      return null;
    }
  }
}

extension GetImagesData on AppState {
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>? get imagesData {
    final cls = this;
    if (cls is AppStateLoggedIn) {
      return cls.imagesData;
    } else {
      return null;
    }
  }
}
