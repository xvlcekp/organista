import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/main/view/main_screen.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/settings_repository.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockAuthBloc extends MockCubit<AuthState> implements AuthBloc {}

class MockPlaylistBloc extends MockCubit<PlaylistState> implements PlaylistBloc {}

class MockFirebaseFirestoreRepository extends Mock implements FirebaseFirestoreRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  const installedVersion = '2.0.0';
  const user = AuthUser(id: 'user-1', email: 'test@example.com', isEmailVerified: true);

  late MockAuthBloc authBloc;
  late MockPlaylistBloc playlistBloc;
  late MockFirebaseFirestoreRepository firestoreRepository;
  late MockSettingsRepository settingsRepository;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Organista',
      packageName: 'sk.anickaapavol.organista',
      version: installedVersion,
      buildNumber: '1',
      buildSignature: '',
    );
    authBloc = MockAuthBloc();
    playlistBloc = MockPlaylistBloc();
    firestoreRepository = MockFirebaseFirestoreRepository();
    settingsRepository = MockSettingsRepository();

    const loggedIn = AuthStateLoggedIn(isLoading: false, user: user);
    when(() => authBloc.state).thenReturn(loggedIn);
    when(() => authBloc.stream).thenAnswer((_) => Stream.value(loggedIn));
    when(() => playlistBloc.state).thenReturn(PlaylistInitState());
    when(() => playlistBloc.stream).thenAnswer((_) => Stream.value(PlaylistInitState()));
    when(() => firestoreRepository.getPlaylistsStream(any())).thenAnswer((_) => const Stream.empty());
    when(() => firestoreRepository.getRepositoriesStream(userId: any(named: 'userId'))).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => settingsRepository.saveLastSeenVersion(any())).thenAnswer((_) async {});
  });

  Widget buildSubject() => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<FirebaseFirestoreRepository>.value(value: firestoreRepository),
      RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<PlaylistBloc>.value(value: playlistBloc),
      ],
      child: const MaterialApp(
        locale: Locale('sk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainScreen(),
      ),
    ),
  );

  // The tabs spin a progress indicator in their initial state, so pumpAndSettle would never settle.
  Future<void> pumpUntilSnackBarShown(WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(); // PackageInfo resolves
    await tester.pump(const Duration(seconds: 1)); // snackbar slides in
  }

  // Lets the snackbar timer expire so the test ends without a pending timer.
  Future<void> dismissSnackBar(WidgetTester tester) =>
      tester.pump(AppConstants.whatsNewSnackBarDuration + const Duration(seconds: 1));

  testWidgets('shows the what\'s-new snackbar on the first run and remembers the version', (tester) async {
    when(() => settingsRepository.getLastSeenVersion()).thenReturn(null);

    await pumpUntilSnackBarShown(tester);

    expect(find.text('Čo je nové vo verzii $installedVersion'), findsOneWidget);
    expect(find.text('Zobraziť'), findsOneWidget);
    verify(() => settingsRepository.saveLastSeenVersion(installedVersion)).called(1);
    await dismissSnackBar(tester);
  });

  testWidgets('shows the what\'s-new snackbar after an update', (tester) async {
    when(() => settingsRepository.getLastSeenVersion()).thenReturn('1.9.0');

    await pumpUntilSnackBarShown(tester);

    expect(find.text('Čo je nové vo verzii $installedVersion'), findsOneWidget);
    verify(() => settingsRepository.saveLastSeenVersion(installedVersion)).called(1);
    await dismissSnackBar(tester);
  });

  testWidgets('stays quiet when the installed version was already seen', (tester) async {
    when(() => settingsRepository.getLastSeenVersion()).thenReturn(installedVersion);

    await pumpUntilSnackBarShown(tester);

    expect(find.byType(SnackBar), findsNothing);
    verifyNever(() => settingsRepository.saveLastSeenVersion(any()));
  });
}
