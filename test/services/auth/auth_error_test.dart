import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/services/auth/auth_error.dart';

void main() {
  test('network-request-failed maps to AuthErrorNetworkRequestFailed instead of an unknown error', () {
    final error = AuthError.from(FirebaseAuthException(code: 'network-request-failed'));

    expect(error, isA<AuthErrorNetworkRequestFailed>());
  });
}
