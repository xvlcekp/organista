import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/services/auth/firebase_auth_provider.dart';

/// Fake platform whose `authenticate` call fails with the scripted [exception],
/// standing in for the native account picker (no method channel needed).
class FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  FakeGoogleSignInPlatform({required this.exception});

  final GoogleSignInException exception;

  @override
  Future<void> init(InitParameters params) async {}

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) async => throw exception;

  @override
  Future<void> signOut(SignOutParams params) async {}

  // The provider never reaches the members below when authentication itself fails.
  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(AttemptLightweightAuthenticationParameters params) =>
      throw UnimplementedError();

  @override
  bool authorizationRequiresUserInteraction() => throw UnimplementedError();

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) => throw UnimplementedError();

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) => throw UnimplementedError();

  @override
  Future<void> disconnect(DisconnectParams params) => throw UnimplementedError();
}

Future<void> _expectSignInThrows<T extends AuthError>(GoogleSignInException exception) async {
  GoogleSignInPlatform.instance = FakeGoogleSignInPlatform(exception: exception);
  await expectLater(FirebaseAuthProvider().signInWithGoogle(), throwsA(isA<T>()));
}

void main() {
  group('FirebaseAuthProvider.signInWithGoogle', () {
    group('maps a genuine user dismissal to AuthErrorSignInCanceled', () {
      // Exact descriptions Google Play Services / Google Sign-In iOS attach when the user closes the picker,
      // as observed in production Sentry events.
      const userDismissals = <String>[
        '[16] Cancelled by user.',
        '[16] User cancelled during add account flow and accounts were present.',
        'User cancelled the selector',
        'The user canceled the sign-in flow.',
      ];

      for (final description in userDismissals) {
        test(description, () async {
          await _expectSignInThrows<AuthErrorSignInCanceled>(
            GoogleSignInException(code: GoogleSignInExceptionCode.canceled, description: description),
          );
        });
      }
    });

    group('keeps ambiguous "canceled" results as AuthErrorGoogleSignInFailed', () {
      // Credential Manager reports some configuration failures (wrong SHA fingerprint, OAuth client type) with
      // the canceled code too. These must stay visible as failures.
      const ambiguousCancels = <String?>[
        '[16] Account reauth failed.',
        'activity is cancelled by the user.',
        null,
      ];

      for (final description in ambiguousCancels) {
        test('$description', () async {
          await _expectSignInThrows<AuthErrorGoogleSignInFailed>(
            GoogleSignInException(code: GoogleSignInExceptionCode.canceled, description: description),
          );
        });
      }
    });

    test('maps any other GoogleSignInException to AuthErrorGoogleSignInFailed', () async {
      await _expectSignInThrows<AuthErrorGoogleSignInFailed>(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'serverClientId must be provided on Android',
        ),
      );
    });
  });
}
