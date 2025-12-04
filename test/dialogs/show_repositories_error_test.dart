import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/features/show_repositories/view/show_repositories_error.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';
import 'package:organista/l10n/app_localizations.dart';

void main() {
  group('show_repositories_error', () {
    late AppLocalizations loc;

    Widget createTestApp({required Widget child}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    }

    Future<String> getErrorMessage(WidgetTester tester, RepositoryError error) async {
      late String message;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
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

    group('getLocalizedMessage', () {
      testWidgets('should return correct messages for all error types', (tester) async {
        // Test all error types in one test to reduce repetition
        final testCases = [
          (const RepositoryGenericException(), () => loc.repositoryGenericError),
          (const RepositoryNotFound(), () => loc.repositoryNotFoundError),
          (const RepositoryCannotModifyPublic(), () => loc.repositoryCannotModifyPublicError),
          (const RepositoryCannotModifyOtherUsers(), () => loc.repositoryCannotModifyOtherUsersError),
          (
            const MaximumRepositoriesCounExceeded(maximumRepositoriesCount: 5),
            () => loc.maximumRepositoriesCountExceededError(5),
          ),
          (RepositoriesErrorUnknown(exception: FirebaseAuthException(code: 'test')), () => loc.errorUnknownText),
        ];

        for (final (error, expectedMessage) in testCases) {
          final message = await getErrorMessage(tester, error);
          expect(message, equals(expectedMessage()));
        }
      });

      testWidgets('should handle different repository counts', (tester) async {
        final counts = [1, 5, 10, 100];

        for (final count in counts) {
          final error = MaximumRepositoriesCounExceeded(maximumRepositoriesCount: count);
          final message = await getErrorMessage(tester, error);
          expect(message, contains(count.toString()));
        }
      });
    });
  });
}
