import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/features/show_playlists/view/playlists_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/widgets/scroll_aware_fab.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/services/auth/auth_user.dart';

// Mock classes
class MockShowPlaylistsCubit extends MockCubit<ShowPlaylistsState> implements ShowPlaylistsCubit {}

class MockAuthBloc extends MockCubit<AuthState> implements AuthBloc {}

class MockPlaylistBloc extends MockCubit<PlaylistState> implements PlaylistBloc {}

void main() {
  group('PlaylistsView Widget Tests', () {
    late MockShowPlaylistsCubit mockShowPlaylistsCubit;
    late MockAuthBloc mockAuthBloc;
    late MockPlaylistBloc mockPlaylistBloc;

    // Test data
    const testUser = AuthUser(
      id: 'test-user-123',
      email: 'test@example.com',
      isEmailVerified: true,
    );

    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));
    final musicSheetTimestamp = Timestamp.fromDate(DateTime(2024, 1, 10, 9, 0));

    final sampleMusicSheetJson = {
      MusicSheetKey.musicSheetId: 'sheet-123',
      MusicSheetKey.userId: 'test-user-123',
      MusicSheetKey.createdAt: musicSheetTimestamp,
      MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
      MusicSheetKey.fileName: 'Amazing Grace.pdf',
      MusicSheetKey.originalFileStorageId: 'storage-123',
      MusicSheetKey.mediaType: 'pdf',
      MusicSheetKey.sequenceId: 1,
    };

    final testPlaylist1 = Playlist(
      playlistId: 'playlist-1',
      json: {
        PlaylistKey.userId: 'test-user-123',
        PlaylistKey.createdAt: testTimestamp,
        PlaylistKey.name: 'Sunday Service',
        PlaylistKey.musicSheets: [sampleMusicSheetJson],
      },
    );

    final testPlaylist2 = Playlist(
      playlistId: 'playlist-2',
      json: {
        PlaylistKey.userId: 'test-user-123',
        PlaylistKey.createdAt: testTimestamp,
        PlaylistKey.name: 'Christmas Songs',
        PlaylistKey.musicSheets: const [],
      },
    );

    setUp(() {
      mockShowPlaylistsCubit = MockShowPlaylistsCubit();
      mockAuthBloc = MockAuthBloc();
      mockPlaylistBloc = MockPlaylistBloc();

      // Setup default states and streams
      when(() => mockAuthBloc.state).thenReturn(
        const AuthStateLoggedIn(isLoading: false, user: testUser),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthStateLoggedIn(isLoading: false, user: testUser),
        ]),
      );

      when(() => mockShowPlaylistsCubit.state).thenReturn(
        const InitPlaylistState(),
      );
      when(() => mockShowPlaylistsCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([const InitPlaylistState()]),
      );

      when(() => mockPlaylistBloc.state).thenReturn(
        PlaylistInitState(),
      );
      when(() => mockPlaylistBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([PlaylistInitState()]),
      );

      // Register fallback values for mocktail
      registerFallbackValue(
        InitPlaylistEvent(
          user: const AuthUser(id: '', email: '', isEmailVerified: false),
          playlist: Playlist.empty(),
        ),
      );
      registerFallbackValue(testPlaylist1);
    });

    Widget createTestWidget({ShowPlaylistsState? initialState}) {
      final state = initialState ?? const InitPlaylistState();
      when(() => mockShowPlaylistsCubit.state).thenReturn(state);
      when(() => mockShowPlaylistsCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([state]),
      );

      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<ShowPlaylistsCubit>.value(value: mockShowPlaylistsCubit),
            BlocProvider<PlaylistBloc>.value(value: mockPlaylistBloc),
          ],
          child: const PlaylistsView(),
        ),
      );
    }

    group('Widget Structure', () {
      testWidgets('should render without Scaffold or AppBar, but with FAB', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(Scaffold), findsNothing);
        expect(find.byType(ScrollAwareFab), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('should display empty state when no playlists exist', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const PlaylistsLoadedState(playlists: []),
          ),
        );

        expect(find.byIcon(Icons.music_off), findsOneWidget);
        expect(find.text('No playlists yet'), findsOneWidget);
        expect(find.textContaining('Create your first playlist'), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      });
    });

    group('Failed changes', () {
      testWidgets('shows an error dialog when a playlist change could not be saved', (tester) async {
        final loaded = PlaylistsLoadedState(playlists: [testPlaylist1]);
        final widget = createTestWidget(initialState: loaded);
        whenListen(
          mockShowPlaylistsCubit,
          Stream.fromIterable([
            PlaylistsLoadedState(playlists: [testPlaylist1], error: const PlaylistErrorUnknown()),
          ]),
          initialState: loaded,
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.text('An error happened'), findsOneWidget);
        expect(find.text('Unknown error'), findsOneWidget);
        expect(find.text('Sunday Service'), findsOneWidget, reason: 'the list stays on screen behind the dialog');
      });
    });

    group('Populated State', () {
      testWidgets('should display list of playlists when playlists exist', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: PlaylistsLoadedState(playlists: [testPlaylist1, testPlaylist2]),
          ),
        );

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Sunday Service'), findsOneWidget);
        expect(find.text('Christmas Songs'), findsOneWidget);
        expect(find.byType(Card), findsNWidgets(2));

        // Check for music sheet count text (may be formatted differently)
        expect(find.textContaining('1'), findsWidgets);
        expect(find.textContaining('0'), findsWidgets);
      });

      testWidgets('should display chevron right icon for navigation', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: PlaylistsLoadedState(playlists: [testPlaylist1]),
          ),
        );

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('should show extended FAB in initial (non-scrolled) state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: PlaylistsLoadedState(playlists: [testPlaylist1, testPlaylist2]),
          ),
        );
        await tester.pump();

        expect(find.byType(ScrollAwareFab), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('Cubit Initialization', () {
      testWidgets('should call startSubscribingPlaylists on initialization', (tester) async {
        await tester.pumpWidget(createTestWidget());

        verify(
          () => mockShowPlaylistsCubit.startSubscribingPlaylists(
            userId: testUser.id,
          ),
        ).called(1);
      });
    });

    group('Long-press menu', () {
      Future<void> openMenu(WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(initialState: PlaylistsLoadedState(playlists: [testPlaylist1])));
        await tester.longPress(find.text('Sunday Service'));
        await tester.pumpAndSettle();
      }

      testWidgets('playlists can no longer be deleted by swiping', (tester) async {
        await tester.pumpWidget(createTestWidget(initialState: PlaylistsLoadedState(playlists: [testPlaylist1])));

        expect(find.byType(Dismissible), findsNothing);
      });

      testWidgets('long press shows rename, duplicate and delete', (tester) async {
        await openMenu(tester);

        expect(find.text('Rename playlist'), findsOneWidget);
        expect(find.text('Duplicate playlist'), findsOneWidget);
        expect(find.text('Delete playlist'), findsOneWidget);
      });

      testWidgets('rename opens the dialog prefilled with the current name and renames the playlist', (tester) async {
        when(
          () => mockShowPlaylistsCubit.editPlaylistName(
            newPlaylistName: any(named: 'newPlaylistName'),
            playlist: any(named: 'playlist'),
          ),
        ).thenAnswer((_) async {});
        await openMenu(tester);

        await tester.tap(find.text('Rename playlist'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextField, 'Sunday Service'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Evening Service');
        await tester.tap(find.text('Rename'));
        await tester.pumpAndSettle();

        verify(
          () => mockShowPlaylistsCubit.editPlaylistName(newPlaylistName: 'Evening Service', playlist: testPlaylist1),
        ).called(1);
      });

      testWidgets('duplicate suggests "<name> (copy)" and accepts the suggestion as it is', (tester) async {
        when(
          () => mockShowPlaylistsCubit.duplicatePlaylist(
            newPlaylistName: any(named: 'newPlaylistName'),
            playlist: any(named: 'playlist'),
          ),
        ).thenAnswer((_) async {});
        await openMenu(tester);

        await tester.tap(find.text('Duplicate playlist'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextField, 'Sunday Service (copy)'), findsOneWidget);

        await tester.tap(find.text('Duplicate'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing, reason: 'the suggested name must not be rejected as unchanged');
        verify(
          () => mockShowPlaylistsCubit.duplicatePlaylist(
            newPlaylistName: 'Sunday Service (copy)',
            playlist: testPlaylist1,
          ),
        ).called(1);
      });

      testWidgets('duplicate rejects the name of the original playlist', (tester) async {
        await openMenu(tester);

        await tester.tap(find.text('Duplicate playlist'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Sunday Service');
        await tester.tap(find.text('Duplicate'));
        await tester.pumpAndSettle();

        expect(find.text('Name cannot be the same as current'), findsOneWidget);
        verifyNever(
          () => mockShowPlaylistsCubit.duplicatePlaylist(
            newPlaylistName: any(named: 'newPlaylistName'),
            playlist: any(named: 'playlist'),
          ),
        );
      });

      testWidgets('delete asks for confirmation and deletes only after confirming', (tester) async {
        when(() => mockShowPlaylistsCubit.deletePlaylist(playlist: any(named: 'playlist'))).thenAnswer((_) async {});
        await openMenu(tester);

        await tester.tap(find.text('Delete playlist'));
        await tester.pumpAndSettle();
        expect(
          find.text('Are you sure you want to delete this playlist? You cannot undo this operation!'),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        verifyNever(() => mockShowPlaylistsCubit.deletePlaylist(playlist: any(named: 'playlist')));

        await tester.longPress(find.text('Sunday Service'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete playlist'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Delete playlist'));
        await tester.pumpAndSettle();

        verify(() => mockShowPlaylistsCubit.deletePlaylist(playlist: testPlaylist1)).called(1);
      });
    });

    group('Basic Interactions', () {
      testWidgets('should have proper widget hierarchy', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: PlaylistsLoadedState(playlists: [testPlaylist1]),
          ),
        );
        await tester.pump();

        expect(find.byType(Scaffold), findsNothing);
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(ScrollAwareFab), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Sunday Service'), findsOneWidget);
      });
    });

    group('Multiple Playlists', () {
      testWidgets('should handle multiple playlists correctly', (tester) async {
        final manyPlaylists = List.generate(
          3,
          (index) => Playlist(
            playlistId: 'playlist-$index',
            json: {
              PlaylistKey.userId: 'test-user-123',
              PlaylistKey.createdAt: testTimestamp,
              PlaylistKey.name: 'Playlist $index',
              PlaylistKey.musicSheets: const [],
            },
          ),
        );

        await tester.pumpWidget(
          createTestWidget(
            initialState: PlaylistsLoadedState(playlists: manyPlaylists),
          ),
        );

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Playlist 0'), findsOneWidget);
        expect(find.text('Playlist 2'), findsOneWidget);
        expect(find.byType(Card), findsNWidgets(3));
      });
    });

    group('State Management', () {
      testWidgets('should handle loading state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const InitPlaylistState(),
          ),
        );

        // Should not crash; scaffold-free — no Scaffold or AppBar
        expect(find.byType(Scaffold), findsNothing);
        expect(find.byType(AppBar), findsNothing);
      });

      testWidgets('should handle empty playlists state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const PlaylistsLoadedState(playlists: []),
          ),
        );

        expect(find.text('No playlists yet'), findsOneWidget);
        expect(find.textContaining('Create your first playlist'), findsOneWidget);
        expect(find.byIcon(Icons.music_off), findsOneWidget);
      });
    });
  });
}
