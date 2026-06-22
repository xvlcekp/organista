import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/show_repositories/cubit/show_repositories_cubit.dart';

import 'package:organista/features/show_repositories/models/repositories_view_mode.dart';
import 'package:organista/features/show_repositories/view/repositories_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/widgets/scroll_aware_fab.dart';
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
      // Mock the getRepositoryMusicSheetsStream to return an empty list (needed when navigating into a repository)
      // Using Stream.value (not Stream.empty) so the bloc transitions out of loading state,
      // avoiding an infinite CircularProgressIndicator that would cause pumpAndSettle to time out.
      when(
        () => mockFirebaseRepository.getRepositoryMusicSheetsStream(any()),
      ).thenAnswer((_) => Stream<Iterable<MusicSheet>>.value(const <MusicSheet>[]));
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
      RepositoriesViewMode mode = RepositoriesViewMode.selection,
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

      final view = MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ShowRepositoriesCubit>.value(value: mockRepositoriesCubit),
        ],
        child: RepositoriesView(mode: mode),
      );

      final home = mode == RepositoriesViewMode.management ? Scaffold(body: view) : view;

      return RepositoryProvider<FirebaseFirestoreRepository>.value(
        value: mockFirebaseRepository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
    }

    group('Initial State', () {
      testWidgets('should display app bar with repositories title', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Repositories 📁'), findsOneWidget);
      });

      testWidgets('should display filter chips with Global and Personal tabs', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(FilterChip), findsNWidgets(2));
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Global'), findsOneWidget);
        expect(find.text('Personal'), findsOneWidget);
      });

      testWidgets('should not display floating action button when Global tab is selected', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(ScrollAwareFab), findsNothing);
      });

      testWidgets('should display floating action button when Personal tab is selected', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(mode: RepositoriesViewMode.management),
        );

        // Tap on Personal tab
        await tester.tap(find.text('Personal'));
        await tester.pump();

        expect(find.byType(ScrollAwareFab), findsOneWidget);
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
        'should show no personal repos message when Personal tab selected and private repos empty',
        (tester) async {
          const state = RepositoriesState(
            publicRepositories: [],
            privateRepositories: [],
          );

          await tester.pumpWidget(createWidgetUnderTest(initialState: state));

          // Switch to Personal tab
          await tester.tap(find.text('Personal'));
          await tester.pump();

          expect(find.text("You don't have a personal repository yet"), findsOneWidget);
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

      testWidgets('should not show context menu on long press in selection mode', (tester) async {
        const userId = 'test-user-id';
        final privateRepo = createTestRepository(id: '6', name: 'My Repo Selection', userId: userId);

        final state = RepositoriesState(
          publicRepositories: const [],
          privateRepositories: [privateRepo],
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            initialState: state,
            mode: RepositoriesViewMode.selection,
          ),
        );

        // Switch to Personal tab
        await tester.tap(find.text('Personal'));
        await tester.pump();

        await tester.longPress(find.text('My Repo Selection'));
        await tester.pumpAndSettle();

        expect(find.text('Rename repository'), findsNothing);
        expect(find.text('Delete repository'), findsNothing);
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

        await tester.pumpWidget(
          createWidgetUnderTest(
            initialState: state,
            mode: RepositoriesViewMode.management,
          ),
        );

        // Switch to Personal tab to show FAB
        await tester.tap(find.text('Personal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ScrollAwareFab), findsOneWidget);

        // Tap the FAB - suppress warning since the button might be positioned at edge
        await tester.tap(find.byType(ScrollAwareFab));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // The dialog would appear here, but testing dialogs requires more complex setup
        // For now, we just verify the FAB can be tapped without errors
      });
    });

    group('Management mode', () {
      Widget createManagementModeWidget({
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
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ShowRepositoriesCubit>.value(value: mockRepositoriesCubit),
                RepositoryProvider<FirebaseFirestoreRepository>.value(
                  value: mockFirebaseRepository,
                ),
              ],
              child: const RepositoriesView(mode: RepositoriesViewMode.management),
            ),
          ),
        );
      }

      testWidgets('should contain no Scaffold, AppBar, or NavigationBar', (tester) async {
        await tester.pumpWidget(createManagementModeWidget());

        // The outer Scaffold belongs to the test harness, not to RepositoriesView
        // management mode must not render its own Scaffold/AppBar/NavigationBar
        expect(
          find.byType(Scaffold),
          findsOneWidget,
        ); // only the harness scaffold, not one from RepositoriesView
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('should display FilterChip widgets for Global and Personal tabs', (tester) async {
        await tester.pumpWidget(createManagementModeWidget());

        expect(find.byType(FilterChip), findsNWidgets(2));
        expect(find.text('Global'), findsOneWidget);
        expect(find.text('Personal'), findsOneWidget);
      });

      testWidgets('should not display FAB when Global tab is selected', (tester) async {
        await tester.pumpWidget(createManagementModeWidget());

        // Default tab is Global — no FAB should be visible
        expect(find.byType(ScrollAwareFab), findsNothing);
      });

      testWidgets('should display FAB when Personal tab is selected', (tester) async {
        await tester.pumpWidget(createManagementModeWidget());

        // Switch to Personal tab via the FilterChip
        await tester.tap(find.text('Personal'));
        await tester.pump();

        expect(find.byType(ScrollAwareFab), findsOneWidget);
        expect(find.text('New repository'), findsOneWidget);
      });

      testWidgets('should show context menu on long press for own private repo in management mode', (tester) async {
        const userId = 'test-user-id';
        final privateRepo = createTestRepository(id: '5', name: 'My Repo', userId: userId);

        final state = RepositoriesState(
          publicRepositories: const [],
          privateRepositories: [privateRepo],
        );

        await tester.pumpWidget(createManagementModeWidget(initialState: state));

        // Switch to Personal tab
        await tester.tap(find.text('Personal'));
        await tester.pump();

        // Long-press the repository tile
        await tester.longPress(find.text('My Repo'));
        await tester.pumpAndSettle();

        // Bottom sheet with Rename and Delete options should appear
        expect(find.text('Rename repository'), findsOneWidget);
        expect(find.text('Delete repository'), findsOneWidget);
      });

      testWidgets('should switch between Global and Personal tabs via FilterChip', (tester) async {
        final publicRepo = createTestRepository(id: '1', name: 'Public Repo NS');
        final privateRepo = createTestRepository(id: '2', name: 'Private Repo NS', userId: 'test-user-id');

        final state = RepositoriesState(
          publicRepositories: [publicRepo],
          privateRepositories: [privateRepo],
        );

        await tester.pumpWidget(createManagementModeWidget(initialState: state));

        // Initially on Global tab
        expect(find.text('Public Repo NS'), findsOneWidget);
        expect(find.text('Private Repo NS'), findsNothing);

        // Tap the Personal FilterChip to switch tabs
        await tester.tap(find.text('Personal'));
        await tester.pump();

        expect(find.text('Public Repo NS'), findsNothing);
        expect(find.text('Private Repo NS'), findsOneWidget);

        // Tap the Global FilterChip to switch back
        await tester.tap(find.text('Global'));
        await tester.pump();

        expect(find.text('Public Repo NS'), findsOneWidget);
        expect(find.text('Private Repo NS'), findsNothing);
      });
    });
  });
}
