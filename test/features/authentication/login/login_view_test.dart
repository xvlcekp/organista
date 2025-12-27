import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/authentication/login/login_view.dart';
import 'package:organista/widgets/email_text_field.dart';
import 'package:organista/widgets/password_text_field.dart';
import 'package:organista/widgets/organista_logo.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

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
        child: const LoginView(),
      ),
    );
  }

  testWidgets('tapping login with empty fields shows SnackBar error', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Clear fields to handle potential debug auto-fill
    await tester.enterText(find.byType(EmailTextField), '');
    await tester.enterText(find.byType(PasswordTextField), '');
    await tester.pumpAndSettle();

    // Tap login button without entering text
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump(); // Start animation
    await tester.pumpAndSettle(); // Finish animation

    // Verify SnackBar appears
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please fill in all fields'), findsOneWidget);

    // Verify no event was added to bloc
    verifyNever(() => mockAuthBloc.add(any()));
  });

  testWidgets('tapping login with valid input triggers AuthEventLogIn', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Enter email
    await tester.enterText(find.byType(EmailTextField), 'test@example.com');

    // Enter password
    await tester.enterText(find.byType(PasswordTextField), 'password123');

    // Tap login button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    // Verify event was added
    final captured = verify(() => mockAuthBloc.add(captureAny())).captured;
    expect(captured.last, isA<AuthEventLogIn>());
    final event = captured.last as AuthEventLogIn;
    expect(event.email, 'test@example.com');
    expect(event.password, 'password123');
  });

  testWidgets('UI layout renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(OrganistaLogo), findsOneWidget);
    expect(find.byType(EmailTextField), findsOneWidget);
    expect(find.byType(PasswordTextField), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('password visibility toggle works', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final passwordFieldFinder = find.byType(PasswordTextField);
    final textField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isTrue); // Defaults to hidden

    // Find the toggle button (Icon button inside PasswordTextField)
    // Looking for the icon specifically might be safer
    final visibilityIcon = find.descendant(of: passwordFieldFinder, matching: find.byType(IconButton));

    await tester.tap(visibilityIcon);
    await tester.pumpAndSettle();

    final textFieldVisible = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
    );
    expect(textFieldVisible.obscureText, isFalse); // Should be visible
  });

  testWidgets('Register button triggers AuthEventGoToRegistration', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register'));
    await tester.pump();

    verify(() => mockAuthBloc.add(const AuthEventGoToRegistration())).called(1);
  });

  testWidgets('Google Sign-In triggers AuthEventSignInWithGoogle', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    verify(() => mockAuthBloc.add(const AuthEventSignInWithGoogle())).called(1);
  });

  testWidgets('Apple Sign-In triggers AuthEventSignInWithApple on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Apple Sign-In button is present
    expect(find.byType(SignInWithAppleButton), findsOneWidget);

    await tester.tap(find.byType(SignInWithAppleButton));
    await tester.pump();

    verify(() => mockAuthBloc.add(const AuthEventSignInWithApple())).called(1);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows SnackBar when password reset email is sent', (tester) async {
    // We need to rebuild the stream to emit a new state
    whenListen(
      mockAuthBloc,
      Stream.fromIterable([
        const AuthStateLoggedOut(isLoading: false, passwordResetSent: true),
      ]),
      initialState: const AuthStateLoggedOut(isLoading: false),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // trigger listener and dialog animation

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Password reset email sent. Please check your inbox.'), findsOneWidget);
  });
}
