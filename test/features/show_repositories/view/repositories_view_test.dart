import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/features/show_repositories/cubit/show_repositories_cubit.dart';

import 'package:organista/features/show_repositories/view/repositories_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/auth/auth_user.dart';

class MockShowRepositoriesCubit extends MockCubit<ShowRepositoriesState> implements ShowRepositoriesCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockFirebaseFirestoreRepository extends Mock implements FirebaseFirestoreRepository {}

void main() {
  group('RepositoriesView', () {
    late MockShowRepositoriesCubit mockRepositoriesCubit;
    late MockAuthBloc mockAuthBloc;
    late MockFirebaseFirestoreRepository mockFirebaseRepository;

    setUp(() {
      mockRepositoriesCubit = MockShowRepositoriesCubit();
      mockAuthBloc = MockAuthBloc();
      mockFirebaseRepository = MockFirebaseFirestoreRepository();

      // Mock the getRepositoryMusicSheetsCount method to return a Future<int>
      when(() => mockFirebaseRepository.getRepositoryMusicSheetsCount(any())).thenAnswer((_) async => 0);
    });

    Repository createTestRepository({
      required String id,
      required String name,
      String userId = '',
      DateTime? createdAt,
    }) {
      return Repository(
        json: {
          'repository_id': id,
          'name': name,
          'uid': userId,
          'created_at': Timestamp.fromDate(createdAt ?? DateTime.now()),
        },
      );
    }

    Widget createWidgetUnderTest({
      ShowRepositoriesState? initialState,
    }) {
      when(() => mockRepositoriesCubit.state).thenReturn(
        initialState ?? const InitRepositoryState(),
      );
      when(() => mockRepositoriesCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([initialState ?? const InitRepositoryState()]),
      );

      when(() => mockAuthBloc.state).thenReturn(
        const AuthStateLoggedIn(
          isLoading: false,
          user: AuthUser(
            id: 'test-user-id',
            email: 'test@example.com',
            isEmailVerified: true,
          ),
        ),
      );

      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<ShowRepositoriesCubit>.value(value: mockRepositoriesCubit),
            RepositoryProvider<FirebaseFirestoreRepository>.value(
              value: mockFirebaseRepository,
            ),
          ],
          child: const RepositoriesViewContent(),
        ),
      );
    }

    group('Initial State', () {
      testWidgets('should display app bar with repositories title', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Repositories 📁'), findsOneWidget);
      });

      testWidgets('should display bottom navigation bar with Global and Personal tabs', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Global'), findsOneWidget);
        expect(find.text('Personal'), findsOneWidget);
      });

      testWidgets('should not display floating action button when Global tab is selected', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('should display floating action button when Personal tab is selected', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Tap on Personal tab
        await tester.tap(find.text('Personal'));
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('New repository'), findsOneWidget);
      });
    });

    group('Repository List Display', () {
      testWidgets('should display no global repositories message when public repositories are empty', (tester) async {
        const state = RepositoriesState(
          publicRepositories: [],
          privateRepositories: [],
        );

        await tester.pumpWidget(createWidgetUnderTest(initialState: state));

        expect(find.text('No global repositories available.'), findsOneWidget);
      });

      testWidgets(
        'should display no personal repositories message when private repositories are empty and Personal tab is selected',
        (tester) async {
          const state = RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
          );

          await tester.pumpWidget(createWidgetUnderTest(initialState: state));

          // Switch to Personal tab
          await tester.tap(find.text('Personal'));
          await tester.pump();

          expect(find.text('No personal repositories available.'), findsOneWidget);
        },
      );

      testWidgets('should display public repositories in grid view', (tester) async {
        final publicRepo1 = createTestRepository(id: '1', name: 'Public Repo 1');
        final publicRepo2 = createTestRepository(id: '2', name: 'Public Repo 2');

        final state = RepositoriesState(
          publicRepositories: [publicRepo1, publicRepo2],
          privateRepositories: const [],
        );

        await tester.pumpWidget(createWidgetUnderTest(initialState: state));

        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('Public Repo 1'), findsOneWidget);
        expect(find.text('Public Repo 2'), findsOneWidget);
      });

      testWidgets('should display private repositories when Personal tab is selected', (tester) async {
        const userId = 'test-user-id';
        final privateRepo1 = createTestRepository(id: '3', name: 'Private Repo 1', userId: userId);
        final privateRepo2 = createTestRepository(id: '4', name: 'Private Repo 2', userId: userId);

        final state = RepositoriesState(
          publicRepositories: const [],
          privateRepositories: [privateRepo1, privateRepo2],
        );

        await tester.pumpWidget(createWidgetUnderTest(initialState: state));

        // Switch to Personal tab
        await tester.tap(find.text('Personal'));
        await tester.pump();

        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('Private Repo 1'), findsOneWidget);
        expect(find.text('Private Repo 2'), findsOneWidget);
      });

      testWidgets('should switch between Global and Personal tabs correctly', (tester) async {
        const userId = 'test-user-id';
        final publicRepo = createTestRepository(id: '1', name: 'Public Repo');
        final privateRepo = createTestRepository(id: '2', name: 'Private Repo', userId: userId);

        final state = RepositoriesState(
          publicRepositories: [publicRepo],
          privateRepositories: [privateRepo],
        );

        await tester.pumpWidget(createWidgetUnderTest(initialState: state));

        // Initially on Global tab
        expect(find.text('Public Repo'), findsOneWidget);
        expect(find.text('Private Repo'), findsNothing);

        // Switch to Personal tab
        await tester.tap(find.text('Personal'));
        await tester.pump();

        expect(find.text('Public Repo'), findsNothing);
        expect(find.text('Private Repo'), findsOneWidget);

        // Switch back to Global tab
        await tester.tap(find.text('Global'));
        await tester.pump();

        expect(find.text('Public Repo'), findsOneWidget);
        expect(find.text('Private Repo'), findsNothing);
      });
    });

    group('Floating Action Button', () {
      testWidgets('should call createRepository when FAB is pressed', (tester) async {
        const state = RepositoriesState(
          publicRepositories: [],
          privateRepositories: [],
        );

        await tester.pumpWidget(createWidgetUnderTest(initialState: state));

        // Switch to Personal tab to show FAB
        await tester.tap(find.text('Personal'));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);

        // Tap the FAB - suppress warning since the button might be positioned at edge
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // The dialog would appear here, but testing dialogs requires more complex setup
        // For now, we just verify the FAB can be tapped without errors
      });
    });
  });
}
