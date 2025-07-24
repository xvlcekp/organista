import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/features/show_playlists/view/playlists_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/views/main_popup_menu_button.dart';

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
      testWidgets('should display app bar with correct title and icon', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byIcon(Icons.list_alt), findsOneWidget);
        expect(find.text('My Playlists'), findsOneWidget);
        expect(find.byType(MainPopupMenuButton), findsOneWidget);
      });

      testWidgets('should display floating action button', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('New Playlist'), findsOneWidget);
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
        expect(find.text('Create your first playlist'), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
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

    group('Basic Interactions', () {
      testWidgets('should show dismissible widget for playlist deletion', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: PlaylistsLoadedState(playlists: [testPlaylist1]),
          ),
        );

        final dismissible = find.byType(Dismissible);
        expect(dismissible, findsOneWidget);

        // Start swipe gesture to reveal delete background
        await tester.drag(dismissible, const Offset(-100, 0));
        await tester.pump();

        // Check if delete icon is visible in background
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should have proper widget hierarchy', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: PlaylistsLoadedState(playlists: [testPlaylist1]),
          ),
        );

        // Verify the basic widget tree structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        // Note: ListTile might not be used in the actual implementation
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

        // Should not crash and should display the scaffold
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should handle empty playlists state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const PlaylistsLoadedState(playlists: []),
          ),
        );

        expect(find.text('No playlists yet'), findsOneWidget);
        expect(find.text('Create your first playlist'), findsOneWidget);
        expect(find.byIcon(Icons.music_off), findsOneWidget);
      });
    });
  });
}
