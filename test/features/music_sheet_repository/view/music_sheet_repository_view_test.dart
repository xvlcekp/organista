import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/music_sheet_repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/view/music_sheet_repository_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/widgets/scroll_aware_fab.dart';
import 'package:provider/provider.dart';

class MockMusicSheetRepositoryBloc extends MockBloc<MusicSheetRepositoryEvent, MusicSheetRepositoryState>
    implements MusicSheetRepositoryBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockCacheManager extends Mock implements CacheManager {}

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
}
