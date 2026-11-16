import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/music_sheet_repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/view/music_sheet_repository_view.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/widgets/scroll_aware_fab.dart';
import 'package:provider/provider.dart';

class MockMusicSheetRepositoryBloc extends MockBloc<MusicSheetRepositoryEvent, MusicSheetRepositoryState>
    implements MusicSheetRepositoryBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockCacheManager extends Mock implements CacheManager {}

class MockAddEditMusicSheetCubit extends MockCubit<AddEditMusicSheetState> implements AddEditMusicSheetCubit {}

class MockPlaylistBloc extends MockBloc<PlaylistEvent, PlaylistState> implements PlaylistBloc {}

/// A picked file whose size is known up front and whose content is read only on demand.
final class FakePlatformFile extends PlatformFile {
  FakePlatformFile({required this.name, required this.size, Uint8List? content}) : _content = content;

  @override
  final String name;
  final int size;
  final Uint8List? _content;
  bool contentRead = false;

  @override
  Uri get uri => Uri.file('/picked/$name');

  // Not used by the upload; the type is inferred from PlatformFile, so cross_file need not be a dependency.
  @override
  get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => size;

  @override
  Future<int?> length() async => size;

  @override
  Future<Uint8List> readAsBytes() async {
    contentRead = true;
    return _content ?? Uint8List(0);
  }

  @override
  Stream<Uint8List> readAsByteStream() => Stream.fromFuture(readAsBytes());
}

/// Stands in for the native file picker and returns [picked].
class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform(this.picked);

  final PlatformFile picked;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => picked;
}

void main() {
  late MockMusicSheetRepositoryBloc mockBloc;
  late MockAuthBloc mockAuthBloc;
  late MockCacheManager mockCacheManager;
  late MusicSheet testMusicSheet;
  late Repository testRepository;

  setUp(() {
    mockBloc = MockMusicSheetRepositoryBloc();
    mockAuthBloc = MockAuthBloc();
    mockCacheManager = MockCacheManager();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthStateLoggedIn(
        isLoading: false,
        user: AuthUser(id: 'user-1', email: 'test@example.com', isEmailVerified: true),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCacheManager.getFileFromCache(any())).thenAnswer((_) async => null);

    testMusicSheet = MusicSheet(
      json: {
        MusicSheetKey.musicSheetId: 'sheet-1',
        MusicSheetKey.userId: 'user-1',
        MusicSheetKey.createdAt: Timestamp.now(),
        MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
        MusicSheetKey.fileName: 'Test Sheet',
        MusicSheetKey.originalFileStorageId: 'storage-1',
        MusicSheetKey.mediaType: 'pdf',
        MusicSheetKey.sequenceId: 0,
        MusicSheetKey.transposition: 0,
      },
    );

    testRepository = Repository(
      json: {
        'repository_id': 'repo-1',
        'name': 'Test Repo',
        'uid': 'user-1',
        'created_at': Timestamp.fromDate(DateTime(2025)),
      },
    );

    final loadedState = MusicSheetRepositoryLoaded(
      allMusicSheets: [testMusicSheet],
      filteredMusicSheets: [testMusicSheet],
    );
    when(() => mockBloc.state).thenReturn(loadedState);
    when(() => mockBloc.stream).thenAnswer((_) => Stream.value(loadedState));
  });

  Widget buildView({bool viewOnly = false}) {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: BlocProvider<MusicSheetRepositoryBloc>.value(
        value: mockBloc,
        child: Provider<CacheManager>.value(
          value: mockCacheManager,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MusicSheetRepositoryView(
              repository: testRepository,
              viewOnly: viewOnly,
            ),
          ),
        ),
      ),
    );
  }

  group('MusicSheetRepositoryView', () {
    testWidgets('does not enter selection mode on long press when viewOnly is true', (tester) async {
      await tester.pumpWidget(buildView(viewOnly: true));
      await tester.pump();

      await tester.longPress(find.text('Test Sheet'));
      await tester.pump();

      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('enters selection mode on long press when viewOnly is false', (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pump();

      await tester.longPress(find.text('Test Sheet'));
      await tester.pump();

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('shows ScrollAwareFab for private repository', (tester) async {
      // testRepository has uid='user-1' (non-empty) so isPrivate=true
      await tester.pumpWidget(buildView());
      await tester.pump();

      expect(find.byType(ScrollAwareFab), findsOneWidget);
    });

    testWidgets('hides ScrollAwareFab for public repository', (tester) async {
      final publicRepository = Repository(
        json: {
          'repository_id': 'repo-public',
          'name': 'Public Repo',
          'uid': '', // isPrivate = false when userId is empty
          'created_at': Timestamp.fromDate(DateTime(2025)),
        },
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: BlocProvider<MusicSheetRepositoryBloc>.value(
            value: mockBloc,
            child: Provider<CacheManager>.value(
              value: mockCacheManager,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: MusicSheetRepositoryView(repository: publicRepository),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ScrollAwareFab), findsNothing);
    });

    testWidgets('hides ScrollAwareFab when in selection mode', (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pump();

      await tester.longPress(find.text('Test Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(ScrollAwareFab), findsNothing);
    });
  });

  group('adding selected sheets to the playlist', () {
    MusicSheet sheet(String id, String name) => MusicSheet(
      json: {
        MusicSheetKey.musicSheetId: id,
        MusicSheetKey.userId: 'user-1',
        MusicSheetKey.createdAt: Timestamp.now(),
        MusicSheetKey.fileUrl: 'https://example.com/$id.pdf',
        MusicSheetKey.fileName: name,
        MusicSheetKey.originalFileStorageId: 'storage-$id',
        MusicSheetKey.mediaType: 'pdf',
        MusicSheetKey.sequenceId: 0,
        MusicSheetKey.transposition: 0,
      },
    );

    testWidgets('keeps sheets selected under an earlier search query', (tester) async {
      final angel = sheet('sheet-a', 'Anjel Pána');
      final lord = sheet('sheet-b', 'Bože, čo si Ty');
      final all = [angel, lord];
      final states = StreamController<MusicSheetRepositoryState>.broadcast();
      addTearDown(states.close);
      void emit(MusicSheetRepositoryLoaded state) {
        when(() => mockBloc.state).thenReturn(state);
        states.add(state);
      }

      when(() => mockBloc.stream).thenAnswer((_) => states.stream);
      when(() => mockBloc.state).thenReturn(MusicSheetRepositoryLoaded(allMusicSheets: all, filteredMusicSheets: all));

      final playlistBloc = MockPlaylistBloc();
      final playlist = Playlist.empty();
      when(() => playlistBloc.state).thenReturn(PlaylistLoadedState(isLoading: false, playlist: playlist));

      await tester.pumpWidget(BlocProvider<PlaylistBloc>.value(value: playlistBloc, child: buildView()));
      await tester.pump();

      emit(MusicSheetRepositoryLoaded(allMusicSheets: all, filteredMusicSheets: [angel], searchQuery: 'anjel'));
      await tester.pump();
      await tester.longPress(find.text('Anjel Pána'));
      await tester.pump();

      emit(MusicSheetRepositoryLoaded(allMusicSheets: all, filteredMusicSheets: [lord], searchQuery: 'bože'));
      await tester.pump();
      await tester.tap(find.text('Bože, čo si Ty'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pump();

      verify(() => playlistBloc.add(AddMusicSheetsToPlaylistEvent(musicSheets: all, playlist: playlist))).called(1);
    });
  });

  group('uploading a picked file', () {
    late MockAddEditMusicSheetCubit mockAddEditCubit;

    setUp(() {
      mockAddEditCubit = MockAddEditMusicSheetCubit();
      when(() => mockAddEditCubit.state).thenReturn(const InitMusicSheetState());
      registerFallbackValue(MusicSheetFile.fromBytes(name: 'fallback.pdf', bytes: Uint8List(0)));
    });

    Future<void> pick(WidgetTester tester, PlatformFile picked) async {
      final previousPicker = FilePickerPlatform.instance;
      FilePickerPlatform.instance = FakeFilePickerPlatform(picked);
      addTearDown(() => FilePickerPlatform.instance = previousPicker);

      await tester.pumpWidget(
        BlocProvider<AddEditMusicSheetCubit>.value(value: mockAddEditCubit, child: buildView()),
      );
      await tester.pump();
      await tester.tap(find.byType(ScrollAwareFab));
      await tester.pump();
    }

    testWidgets('rejects a file over the limit without reading it', (tester) async {
      // ORGANISTA-6M: a 110 MB file was read into memory before the size check and crashed with OutOfMemoryError.
      final huge = FakePlatformFile(name: 'huge.pdf', size: AppConstants.maxFileSizeBytes + 1);

      await pick(tester, huge);

      expect(huge.contentRead, isFalse);
      expect(find.text('File is too large. Maximum size is ${AppConstants.maxFileSizeMB}MB.'), findsOneWidget);
      verifyNever(
        () => mockAddEditCubit.uploadMusicSheet(
          file: any(named: 'file'),
          repositoryId: any(named: 'repositoryId'),
        ),
      );
    });

    testWidgets('reads an accepted file and hands it to the upload', (tester) async {
      await pick(tester, FakePlatformFile(name: 'sheet.pdf', size: 3, content: Uint8List.fromList([1, 2, 3])));

      final uploaded =
          verify(
                () => mockAddEditCubit.uploadMusicSheet(
                  file: captureAny(named: 'file'),
                  repositoryId: 'repo-1',
                ),
              ).captured.single
              as MusicSheetFile;
      expect(uploaded.name, 'sheet.pdf');
      expect(uploaded.bytes, [1, 2, 3]);
    });
  });
}
