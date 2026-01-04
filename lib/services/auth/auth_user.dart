import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final String id;
  final String email;
  final bool isEmailVerified;
  final DateTime? lastSignInTime;

  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    this.lastSignInTime,
  });

  factory AuthUser.fromFirebase(User user) => AuthUser(
    id: user.uid,
    email: user.email!,
    isEmailVerified: user.emailVerified,
    lastSignInTime: user.metadata.lastSignInTime,
  );
}
