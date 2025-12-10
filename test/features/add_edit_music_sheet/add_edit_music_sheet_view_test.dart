import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_edit_music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
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
      final mockPlatformFile = PlatformFile(
        name: 'test.pdf',
        size: 1024,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      final mockFile = MusicSheetFile(
        file: mockPlatformFile,
        mediaType: MediaType.pdf,
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
  });
}
