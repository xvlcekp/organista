import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/authentication/register/register_view.dart';
import 'package:organista/widgets/email_text_field.dart';
import 'package:organista/widgets/password_text_field.dart';
import 'package:organista/widgets/organista_logo.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeAuthState extends Fake implements AuthState {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(const AuthStateLoggedOut(isLoading: false));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const RegisterView(),
      ),
    );
  }

  testWidgets('UI layout renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(OrganistaLogo), findsOneWidget);
    expect(find.byType(EmailTextField), findsOneWidget);
    // There are two PasswordTextFields: one for password, one for verify
    expect(find.byType(PasswordTextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    // Check for "Login" link text presence
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows error dialog when email is empty', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Clear fields
    await tester.enterText(find.byType(EmailTextField), '');
    await tester.enterText(find.byType(PasswordTextField).at(0), 'password123');
    await tester.enterText(find.byType(PasswordTextField).at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);

    // Dismiss dialog for cleanliness (optional but good practice)
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows error dialog when password is empty', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EmailTextField), 'test@example.com');
    await tester.enterText(find.byType(PasswordTextField).at(0), '');
    await tester.enterText(find.byType(PasswordTextField).at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('shows error dialog when verify password is empty', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EmailTextField), 'test@example.com');
    await tester.enterText(find.byType(PasswordTextField).at(0), 'password123');
    await tester.enterText(find.byType(PasswordTextField).at(1), '');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Please verify your password'), findsOneWidget);
  });

  testWidgets('shows error dialog when passwords do not match', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EmailTextField), 'test@example.com');
    await tester.enterText(find.byType(PasswordTextField).at(0), 'password123');
    await tester.enterText(find.byType(PasswordTextField).at(1), 'password456');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('triggers AuthEventRegister when inputs are valid', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EmailTextField), 'test@example.com');
    await tester.enterText(find.byType(PasswordTextField).at(0), 'password123');
    await tester.enterText(find.byType(PasswordTextField).at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();

    final captured = verify(() => mockAuthBloc.add(captureAny())).captured;
    expect(captured.last, isA<AuthEventRegister>());
    final event = captured.last as AuthEventRegister;
    expect(event.email, 'test@example.com');
    expect(event.password, 'password123');
  });

  testWidgets('triggers AuthEventGoToLogin when login link is tapped', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Use find.widgetWithText(TextButton, 'Login') or straightforward tap if non-ambiguous
    // However, 'Login' text is inside the TextButton.
    // The link is strictly "Login".
    await tester.tap(find.text('Login'));
    await tester.pump();

    verify(() => mockAuthBloc.add(const AuthEventGoToLogin())).called(1);
  });

  testWidgets('password visibility toggles independently', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final passwordFields = find.byType(PasswordTextField);
    final firstField = passwordFields.at(0);
    final secondField = passwordFields.at(1);

    // Initial state: both obscured
    expect(
      tester.widget<TextField>(find.descendant(of: firstField, matching: find.byType(TextField))).obscureText,
      isTrue,
    );
    expect(
      tester.widget<TextField>(find.descendant(of: secondField, matching: find.byType(TextField))).obscureText,
      isTrue,
    );

    // Toggle first field
    final firstToggle = find.descendant(of: firstField, matching: find.byType(IconButton));
    await tester.tap(firstToggle);
    await tester.pumpAndSettle();

    // Verify first is visible, second still obscured
    expect(
      tester.widget<TextField>(find.descendant(of: firstField, matching: find.byType(TextField))).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.descendant(of: secondField, matching: find.byType(TextField))).obscureText,
      isTrue,
    );

    // Toggle second field
    final secondToggle = find.descendant(of: secondField, matching: find.byType(IconButton));
    await tester.tap(secondToggle);
    await tester.pumpAndSettle();

    // Verify both visible
    expect(
      tester.widget<TextField>(find.descendant(of: firstField, matching: find.byType(TextField))).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.descendant(of: secondField, matching: find.byType(TextField))).obscureText,
      isFalse,
    );
  });
}
