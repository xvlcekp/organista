import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/error/add_edit_music_sheet_error.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_edit_music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:provider/provider.dart';

import 'add_edit_music_sheet_cubit_test.mocks.dart';

class AddEditMusicSheetViewTest extends AddEditMusicSheetCubit {
  AddEditMusicSheetViewTest({
    required FirebaseFirestoreRepository firestoreRepository,
    required FirebaseStorageRepository storageRepository,
  }) : super(
         firebaseFirestoreRepository: firestoreRepository,
         firebaseStorageRepository: storageRepository,
       );

  void setStateForTest(AddEditMusicSheetState state) => emit(state);
}

class MockPlaylistBloc extends MockCubit<PlaylistState> implements PlaylistBloc {}

/// A [CacheManager] whose unstubbed calls throw synchronously, avoiding real network
/// access when a test only needs `MusicSheetView` to render (its loading result is unused).
class MockCacheManager extends Mock implements CacheManager {}

/// Stands in for [PlaylistView] on the navigation stack so `popUntilRoute<PlaylistView>`
/// can find it without pulling in PlaylistView's full provider dependencies.
class FakePlaylistView extends PlaylistView {
  const FakePlaylistView({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A minimal valid 1x1 transparent PNG, so `Image.memory` can decode it without
/// throwing (unlike arbitrary placeholder bytes).
final validPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGNgAAIAAAUAAen63NgAAAAASUVORK5CYII=',
);

void main() {
  group('AddEditMusicSheetView', () {
    late MockFirebaseFirestoreRepository mockFirestoreRepository;
    late MockFirebaseStorageRepository mockStorageRepository;

    setUp(() {
      mockFirestoreRepository = MockFirebaseFirestoreRepository();
      mockStorageRepository = MockFirebaseStorageRepository();
    });

    testWidgets('shows loading indicator for init state', (tester) async {
      final cubit = AddEditMusicSheetViewTest(
        firestoreRepository: mockFirestoreRepository,
        storageRepository: mockStorageRepository,
      )..setStateForTest(const InitMusicSheetState());
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: Provider<CacheManager>.value(
            value: DefaultCacheManager(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AddEditMusicSheetView(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders music sheet preview for edit state', (tester) async {
      final mockPlaylist = Playlist.empty();
      final mockMusicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'sheet-123',
          MusicSheetKey.userId: 'user-123',
          MusicSheetKey.createdAt: Timestamp.fromDate(DateTime.now()),
          MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
          MusicSheetKey.fileName: 'test.pdf',
          MusicSheetKey.originalFileStorageId: 'storage-123',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 1,
        },
      );
      final cubit =
          AddEditMusicSheetViewTest(
            firestoreRepository: mockFirestoreRepository,
            storageRepository: mockStorageRepository,
          )..setStateForTest(
            EditMusicSheetState(
              playlist: mockPlaylist,
              musicSheet: mockMusicSheet,
            ),
          );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: Provider<CacheManager>.value(
            value: DefaultCacheManager(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AddEditMusicSheetView(),
            ),
          ),
        ),
      );

      expect(find.byType(MusicSheetView), findsOneWidget);
      expect(find.text('test.pdf'), findsOneWidget);
    });

    testWidgets('does not pop while loading upload', (tester) async {
      final mockFile = MusicSheetFile(
        file: PlatformFile(
          name: 'test.png',
          size: 0,
          bytes: null,
        ),
        mediaType: MediaType.image,
      );
      final cubit =
          AddEditMusicSheetViewTest(
            firestoreRepository: mockFirestoreRepository,
            storageRepository: mockStorageRepository,
          )..setStateForTest(
            UploadMusicSheetState(
              file: mockFile,
              repositoryId: 'repo-1',
              isLoading: true,
            ),
          );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: Provider<CacheManager>.value(
            value: DefaultCacheManager(),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddEditMusicSheetView(),
                        ),
                      );
                    },
                    child: const Text('go'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AddEditMusicSheetView), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();

      expect(find.byType(AddEditMusicSheetView), findsOneWidget);
    });

    test('route() returns a MaterialPageRoute building AddEditMusicSheetView', () {
      final route = AddEditMusicSheetView.route();

      expect(route, isA<MaterialPageRoute<void>>());
    });

    testWidgets('shows placeholder text when uploaded file has no bytes', (tester) async {
      final mockFile = MusicSheetFile(
        file: PlatformFile(name: 'test.png', size: 0, bytes: null),
        mediaType: MediaType.image,
      );
      final cubit =
          AddEditMusicSheetViewTest(
            firestoreRepository: mockFirestoreRepository,
            storageRepository: mockStorageRepository,
          )..setStateForTest(
            UploadMusicSheetState(file: mockFile, repositoryId: 'repo-1'),
          );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: Provider<CacheManager>.value(
            value: DefaultCacheManager(),
            child: const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AddEditMusicSheetView(),
            ),
          ),
        ),
      );

      expect(find.text('No file data available'), findsOneWidget);
    });

    testWidgets('renders a music sheet preview when the uploaded file has bytes', (tester) async {
      final mockFile = MusicSheetFile(
        file: PlatformFile(name: 'test.png', size: validPngBytes.length, bytes: validPngBytes),
        mediaType: MediaType.image,
      );
      final cubit =
          AddEditMusicSheetViewTest(
            firestoreRepository: mockFirestoreRepository,
            storageRepository: mockStorageRepository,
          )..setStateForTest(
            UploadMusicSheetState(file: mockFile, repositoryId: 'repo-1'),
          );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: Provider<CacheManager>.value(
            value: DefaultCacheManager(),
            child: const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AddEditMusicSheetView(),
            ),
          ),
        ),
      );

      expect(find.byType(MusicSheetView), findsOneWidget);
      expect(find.text('No file data available'), findsNothing);
    });

    group('AddMusicSheetToPlaylistState', () {
      late MockPlaylistBloc mockPlaylistBloc;
      late MockCacheManager mockCacheManager;
      late MusicSheet mockMusicSheet;
      late Playlist mockPlaylist;

      setUp(() {
        mockPlaylistBloc = MockPlaylistBloc();
        mockCacheManager = MockCacheManager();
        mockMusicSheet = MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'sheet-123',
            MusicSheetKey.userId: 'user-123',
            MusicSheetKey.createdAt: Timestamp.fromDate(DateTime.now()),
            MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
            MusicSheetKey.fileName: 'candidate.pdf',
            MusicSheetKey.originalFileStorageId: 'storage-123',
            MusicSheetKey.mediaType: 'pdf',
            MusicSheetKey.sequenceId: 1,
          },
        );
        mockPlaylist = Playlist.empty();
        when(() => mockPlaylistBloc.state).thenReturn(
          PlaylistLoadedState(isLoading: false, playlist: mockPlaylist),
        );
        when(() => mockPlaylistBloc.stream).thenAnswer((_) => const Stream.empty());
        registerFallbackValue(
          AddMusicSheetsToPlaylistEvent(musicSheets: const [], playlist: mockPlaylist),
        );
      });

      Widget buildApp(AddEditMusicSheetCubit cubit) {
        return BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: BlocProvider<PlaylistBloc>.value(
            value: mockPlaylistBloc,
            child: Provider<CacheManager>.value(
              value: mockCacheManager,
              child: const MaterialApp(
                locale: Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: AddEditMusicSheetView(),
              ),
            ),
          ),
        );
      }

      testWidgets('renders music sheet preview from the repository candidate', (tester) async {
        final cubit = AddEditMusicSheetViewTest(
          firestoreRepository: mockFirestoreRepository,
          storageRepository: mockStorageRepository,
        )..setStateForTest(AddMusicSheetToPlaylistState(musicSheet: mockMusicSheet));
        addTearDown(cubit.close);

        await tester.pumpWidget(buildApp(cubit));

        expect(find.byType(MusicSheetView), findsOneWidget);
        expect(find.text('candidate.pdf'), findsOneWidget);
      });

      testWidgets('tapping save dispatches AddMusicSheetsToPlaylistEvent and shows the playlist', (
        tester,
      ) async {
        final cubit = AddEditMusicSheetViewTest(
          firestoreRepository: mockFirestoreRepository,
          storageRepository: mockStorageRepository,
        )..setStateForTest(AddMusicSheetToPlaylistState(musicSheet: mockMusicSheet));
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FakePlaylistView()),
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => buildApp(cubit)),
                    );
                  },
                  child: const Text('go'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final captured = verify(() => mockPlaylistBloc.add(captureAny())).captured;
        expect(captured.single, isA<AddMusicSheetsToPlaylistEvent>());
        final event = captured.single as AddMusicSheetsToPlaylistEvent;
        expect(event.musicSheets.single.fileName, 'candidate.pdf');
        expect(find.byType(AddEditMusicSheetView), findsNothing);
      });
    });

    group('listener side effects', () {
      late MockCacheManager mockCacheManager;
      late Playlist mockPlaylist;
      late MusicSheet mockMusicSheet;

      setUp(() {
        mockCacheManager = MockCacheManager();
        mockPlaylist = Playlist.empty();
        mockMusicSheet = MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'sheet-1',
            MusicSheetKey.userId: 'user-1',
            MusicSheetKey.createdAt: Timestamp.fromDate(DateTime.now()),
            MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
            MusicSheetKey.fileName: 'sheet.pdf',
            MusicSheetKey.originalFileStorageId: 'storage-1',
            MusicSheetKey.mediaType: 'pdf',
            MusicSheetKey.sequenceId: 1,
          },
        );
      });

      Widget buildAppWithGoButton(AddEditMusicSheetCubit cubit, {bool withPlaylistMarker = false}) {
        return MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  if (withPlaylistMarker) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FakePlaylistView()),
                    );
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<AddEditMusicSheetCubit>.value(
                        value: cubit,
                        child: Provider<CacheManager>.value(
                          value: mockCacheManager,
                          child: const AddEditMusicSheetView(),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('go'),
              );
            },
          ),
        );
      }

      testWidgets('shows a snackbar when renaming fails', (tester) async {
        final cubit =
            AddEditMusicSheetViewTest(
              firestoreRepository: mockFirestoreRepository,
              storageRepository: mockStorageRepository,
            )..setStateForTest(
              EditMusicSheetState(playlist: mockPlaylist, musicSheet: mockMusicSheet, isLoading: true),
            );
        addTearDown(cubit.close);

        await tester.pumpWidget(buildAppWithGoButton(cubit));
        await tester.tap(find.text('go'));
        // A bounded pump, not pumpAndSettle: the loading overlay's CircularProgressIndicator
        // animates indefinitely while isLoading is true, so pumpAndSettle would time out.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        cubit.setStateForTest(
          EditMusicSheetState(
            playlist: mockPlaylist,
            musicSheet: mockMusicSheet,
            isLoading: false,
            error: const RenameMusicSheetFailedError(),
          ),
        );
        await tester.pump();

        expect(
          find.textContaining('Failed to rename music sheet'),
          findsOneWidget,
        );
      });

      testWidgets('shows a snackbar for an unknown error', (tester) async {
        final cubit =
            AddEditMusicSheetViewTest(
              firestoreRepository: mockFirestoreRepository,
              storageRepository: mockStorageRepository,
            )..setStateForTest(
              EditMusicSheetState(playlist: mockPlaylist, musicSheet: mockMusicSheet, isLoading: true),
            );
        addTearDown(cubit.close);

        await tester.pumpWidget(buildAppWithGoButton(cubit));
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        cubit.setStateForTest(
          EditMusicSheetState(
            playlist: mockPlaylist,
            musicSheet: mockMusicSheet,
            isLoading: false,
            error: const AddEditMusicSheetErrorUnknown(),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Unknown error'), findsOneWidget);
      });

      testWidgets('shows a snackbar when uploading the record fails', (tester) async {
        final mockFile = MusicSheetFile(
          file: PlatformFile(name: 'test.png', size: 0, bytes: null),
          mediaType: MediaType.image,
        );
        final cubit =
            AddEditMusicSheetViewTest(
              firestoreRepository: mockFirestoreRepository,
              storageRepository: mockStorageRepository,
            )..setStateForTest(
              UploadMusicSheetState(file: mockFile, repositoryId: 'repo-1', isLoading: true),
            );
        addTearDown(cubit.close);

        await tester.pumpWidget(buildAppWithGoButton(cubit));
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        cubit.setStateForTest(
          UploadMusicSheetState(
            file: mockFile,
            repositoryId: 'repo-1',
            isLoading: false,
            error: const UploadMusicSheetRecordFailedError(),
          ),
        );
        await tester.pump();

        expect(
          find.textContaining('Failed to save music sheet record'),
          findsOneWidget,
        );
      });

      testWidgets('pops the screen after a successful upload', (tester) async {
        final mockFile = MusicSheetFile(
          file: PlatformFile(name: 'test.png', size: 0, bytes: null),
          mediaType: MediaType.image,
        );
        final cubit =
            AddEditMusicSheetViewTest(
              firestoreRepository: mockFirestoreRepository,
              storageRepository: mockStorageRepository,
            )..setStateForTest(
              UploadMusicSheetState(file: mockFile, repositoryId: 'repo-1', isLoading: true),
            );
        addTearDown(cubit.close);

        await tester.pumpWidget(buildAppWithGoButton(cubit));
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AddEditMusicSheetView), findsOneWidget);

        cubit.setStateForTest(
          UploadMusicSheetState(file: mockFile, repositoryId: 'repo-1', isLoading: false),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddEditMusicSheetView), findsNothing);
      });

      testWidgets('navigates back to the playlist after a successful rename', (tester) async {
        final cubit =
            AddEditMusicSheetViewTest(
              firestoreRepository: mockFirestoreRepository,
              storageRepository: mockStorageRepository,
            )..setStateForTest(
              EditMusicSheetState(playlist: mockPlaylist, musicSheet: mockMusicSheet, isLoading: true),
            );
        addTearDown(cubit.close);

        await tester.pumpWidget(buildAppWithGoButton(cubit, withPlaylistMarker: true));
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AddEditMusicSheetView), findsOneWidget);

        cubit.setStateForTest(
          EditMusicSheetState(playlist: mockPlaylist, musicSheet: mockMusicSheet, isLoading: false),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AddEditMusicSheetView), findsNothing);
      });
    });

    group('discard changes dialog', () {
      late MockCacheManager mockCacheManager;
      late MusicSheet mockMusicSheet;
      late Playlist mockPlaylist;

      setUp(() {
        mockCacheManager = MockCacheManager();
        mockPlaylist = Playlist.empty();
        mockMusicSheet = MusicSheet(
          json: {
            MusicSheetKey.musicSheetId: 'sheet-1',
            MusicSheetKey.userId: 'user-1',
            MusicSheetKey.createdAt: Timestamp.fromDate(DateTime.now()),
            MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
            MusicSheetKey.fileName: 'sheet.pdf',
            MusicSheetKey.originalFileStorageId: 'storage-1',
            MusicSheetKey.mediaType: 'pdf',
            MusicSheetKey.sequenceId: 1,
          },
        );
      });

      Widget buildApp(AddEditMusicSheetCubit cubit) {
        return BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: Provider<CacheManager>.value(
            value: mockCacheManager,
            child: const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AddEditMusicSheetView(),
            ),
          ),
        );
      }

      testWidgets('confirming discard resets the cubit and pops', (tester) async {
        final cubit =
            AddEditMusicSheetViewTest(
              firestoreRepository: mockFirestoreRepository,
              storageRepository: mockStorageRepository,
            )..setStateForTest(
              EditMusicSheetState(playlist: mockPlaylist, musicSheet: mockMusicSheet),
            );
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => buildApp(cubit)),
                  ),
                  child: const Text('go'),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();

        expect(find.text('Discard Changes'), findsWidgets);

        await tester.tap(find.widgetWithText(TextButton, 'Discard Changes'));
        await tester.pumpAndSettle();

        expect(find.byType(AddEditMusicSheetView), findsNothing);
        expect(cubit.state, isA<InitMusicSheetState>());
      });

      testWidgets('cancelling discard keeps the current screen and state', (tester) async {
        final cubit =
            AddEditMusicSheetViewTest(
              firestoreRepository: mockFirestoreRepository,
              storageRepository: mockStorageRepository,
            )..setStateForTest(
              EditMusicSheetState(playlist: mockPlaylist, musicSheet: mockMusicSheet),
            );
        addTearDown(cubit.close);

        await tester.pumpWidget(buildApp(cubit));

        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AddEditMusicSheetView), findsOneWidget);
        expect(cubit.state, isA<EditMusicSheetState>());
      });
    });

    testWidgets('tapping save with InitMusicSheetState does nothing', (tester) async {
      final cubit = AddEditMusicSheetViewTest(
        firestoreRepository: mockFirestoreRepository,
        storageRepository: mockStorageRepository,
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider<AddEditMusicSheetCubit>.value(
          value: cubit,
          child: Provider<CacheManager>.value(
            value: DefaultCacheManager(),
            child: const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AddEditMusicSheetView(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(cubit.state, isA<InitMusicSheetState>());
      expect(find.byType(AddEditMusicSheetView), findsOneWidget);
    });
  });
}
