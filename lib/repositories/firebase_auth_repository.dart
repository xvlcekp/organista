import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

class FirebaseAuthRepository {
  final Iterable<MusicSheet> musicSheets = [];
  final instance = FirebaseAuth.instance;

  Future<UserCredential> logIn(String email, String password) {
    return instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) {
    return instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) {
    return instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  User? getCurrentUser() {
    return instance.currentUser;
  }

  Future<void> signOut() {
    return instance.signOut();
  }
}
