import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/music_sheet_repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/view/music_sheet_repository_tile.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:provider/provider.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockCacheManager extends Mock implements CacheManager {}

class MockAddEditMusicSheetCubit extends MockCubit<AddEditMusicSheetState> implements AddEditMusicSheetCubit {}

class MockMusicSheetRepositoryBloc extends MockBloc<MusicSheetRepositoryEvent, MusicSheetRepositoryState>
    implements MusicSheetRepositoryBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockCacheManager mockCacheManager;
  late MockAddEditMusicSheetCubit mockAddEditCubit;
  late MockMusicSheetRepositoryBloc mockRepoBloc;
  late MusicSheet testMusicSheet;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockCacheManager = MockCacheManager();
    mockAddEditCubit = MockAddEditMusicSheetCubit();
    mockRepoBloc = MockMusicSheetRepositoryBloc();

    when(() => mockAuthBloc.state).thenReturn(
      const AuthStateLoggedIn(
        isLoading: false,
        user: AuthUser(id: 'user-1', email: 'test@example.com', isEmailVerified: true),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAddEditCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockRepoBloc.stream).thenAnswer((_) => const Stream.empty());
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
  });

  Widget buildTile({bool viewOnly = false}) {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: BlocProvider<AddEditMusicSheetCubit>.value(
        value: mockAddEditCubit,
        child: BlocProvider<MusicSheetRepositoryBloc>.value(
          value: mockRepoBloc,
          child: Provider<CacheManager>.value(
            value: mockCacheManager,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: MusicSheetRepositoryTile(
                  musicSheet: testMusicSheet,
                  searchBarController: TextEditingController(),
                  repositoryId: 'repo-1',
                  viewOnly: viewOnly,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('MusicSheetRepositoryTile', () {
    testWidgets('hides download button when viewOnly is true', (tester) async {
      await tester.pumpWidget(buildTile(viewOnly: true));
      await tester.pump();

      expect(find.byIcon(Icons.download_rounded), findsNothing);
    });

    testWidgets('shows download button when viewOnly is false', (tester) async {
      await tester.pumpWidget(buildTile());
      await tester.pump();

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });
  });
}
