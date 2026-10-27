import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/dialogs/show_auth_error.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/services/auth/auth_error.dart';

void main() {
  late AppLocalizations loc;

  Future<String> messageFor(WidgetTester tester, AuthError error) async {
    late String message;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            loc = context.loc;
            message = getLocalizedMessage(error, context);
            return Text(message);
          },
        ),
      ),
    );
    return message;
  }

  testWidgets('a failed network request is explained as a missing connection', (tester) async {
    final message = await messageFor(tester, const AuthErrorNetworkRequestFailed());

    expect(message, loc.authErrorNetworkRequestFailedText);
  });

  testWidgets('an unknown error keeps the generic text', (tester) async {
    final message = await messageFor(tester, AuthErrorUnknown(exception: FirebaseAuthException(code: 'odd')));

    expect(message, loc.errorUnknownText);
  });
}
