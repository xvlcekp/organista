import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/cache_management/cubit/cache_cubit.dart';
import 'package:organista/features/cache_management/cubit/cache_state.dart';
import 'package:organista/features/cache_management/view/cache_management_view.dart';
import 'package:organista/l10n/app_localizations.dart';

// Mock classes
class MockCacheCubit extends MockCubit<CacheState> implements CacheCubit {}

void main() {
  group('CacheManagementView Widget Tests', () {
    late MockCacheCubit mockCacheCubit;

    setUp(() {
      mockCacheCubit = MockCacheCubit();
      // Mock methods
      when(() => mockCacheCubit.clearCache()).thenAnswer((_) async {});
      when(() => mockCacheCubit.loadCacheInfo()).thenAnswer((_) async {});
    });

    Widget createTestWidget({CacheState? initialState}) {
      final state = initialState ?? const CacheInitial();
      when(() => mockCacheCubit.state).thenReturn(state);
      when(() => mockCacheCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([state]),
      );

      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<CacheCubit>.value(
          value: mockCacheCubit,
          child: const CacheManagementView(),
        ),
      );
    }

    group('Widget Structure', () {
      testWidgets('should display app bar with correct title', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Storage Management'), findsOneWidget);
      });

      testWidgets('should display cache summary card', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        expect(find.byType(Card), findsNWidgets(2)); // Summary card + Info card
        expect(find.text('Storage Summary'), findsOneWidget);
      });

      testWidgets('should display information card', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        expect(find.text('About Storage'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('should display clear cache button when cache is loaded', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        expect(find.text('Clear storage'), findsOneWidget);
        expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
      });
    });

    group('Cache Initial State', () {
      testWidgets('should display default values when in initial state', (tester) async {
        await tester.pumpWidget(createTestWidget(initialState: const CacheInitial()));

        // Should show 0 files and 0.00 MB (default values)
        expect(find.text('0'), findsOneWidget);
        expect(find.text('0.00 MB'), findsOneWidget);
      });

      testWidgets('should not show enabled clear cache button when in initial state', (tester) async {
        await tester.pumpWidget(createTestWidget(initialState: const CacheInitial()));

        // Button text should still be visible, but button should be disabled
        // We can verify this by checking that tapping it doesn't show dialog
        final clearButtonText = find.text('Clear storage');
        if (clearButtonText.evaluate().isNotEmpty) {
          await tester.tap(clearButtonText);
          await tester.pump();
          // Dialog should not appear
          expect(find.byType(AlertDialog), findsNothing);
        }
      });
    });

    group('Cache Loading State', () {
      testWidgets('should display loading indicators when loading', (tester) async {
        await tester.pumpWidget(createTestWidget(initialState: const CacheLoading()));

        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('should not show enabled clear cache button when loading', (tester) async {
        await tester.pumpWidget(createTestWidget(initialState: const CacheLoading()));

        // Button should be disabled - verify by trying to tap
        final clearButtonText = find.text('Clear storage');
        if (clearButtonText.evaluate().isNotEmpty) {
          await tester.tap(clearButtonText);
          await tester.pump();
          // Dialog should not appear
          expect(find.byType(AlertDialog), findsNothing);
        }
      });
    });

    group('Cache Loaded State', () {
      testWidgets('should display correct file count when cache is loaded', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 10, sizeInMB: 5.5),
          ),
        );

        expect(find.text('10'), findsOneWidget);
      });

      testWidgets('should display correct cache size when cache is loaded', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 10, sizeInMB: 5.5),
          ),
        );

        expect(find.text('5.50 MB'), findsOneWidget);
      });

      testWidgets('should format cache size with 2 decimal places', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 1, sizeInMB: 1.234567),
          ),
        );

        expect(find.text('1.23 MB'), findsOneWidget);
      });

      testWidgets('should enable clear cache button when files exist', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        // Verify button is enabled by checking it can be tapped to show dialog
        final clearButton = find.text('Clear storage');
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('should disable clear cache button when no files exist', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 0, sizeInMB: 0.0),
          ),
        );

        // Button should be disabled - verify by trying to tap
        final clearButtonText = find.text('Clear storage');
        if (clearButtonText.evaluate().isNotEmpty) {
          await tester.tap(clearButtonText);
          await tester.pump();
          // Dialog should not appear
          expect(find.byType(AlertDialog), findsNothing);
        }
      });

      testWidgets('should display file icon and storage icon', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        expect(find.byIcon(Icons.file_present), findsOneWidget);
        expect(find.byIcon(Icons.storage), findsOneWidget);
      });
    });

    group('Cache Error State', () {
      testWidgets('should display default values when error occurs', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheError(message: 'Test error'),
          ),
        );

        expect(find.text('0'), findsOneWidget);
        expect(find.text('0.00 MB'), findsOneWidget);
      });

      testWidgets('should disable clear cache button when error occurs', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheError(message: 'Test error'),
          ),
        );

        // Button should be disabled - verify by trying to tap
        final clearButtonText = find.text('Clear storage');
        if (clearButtonText.evaluate().isNotEmpty) {
          await tester.tap(clearButtonText);
          await tester.pump();
          // Dialog should not appear
          expect(find.byType(AlertDialog), findsNothing);
        }
      });
    });

    group('BlocListener Behavior', () {
      testWidgets('should have BlocListener that listens to CacheCubit', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify that BlocListener is present in the widget tree
        expect(find.byType(BlocListener<CacheCubit, CacheState>), findsAtLeastNWidgets(1));

        // Verify that the BlocListener is listening to CacheCubit
        final blocListeners = tester.widgetList<BlocListener<CacheCubit, CacheState>>(
          find.byType(BlocListener<CacheCubit, CacheState>),
        );
        expect(blocListeners.isNotEmpty, isTrue);
        // Verify that at least one BlocListener has a listener function
        final viewBlocListener = blocListeners.first;
        expect(viewBlocListener.listener, isNotNull);
      });
    });

    group('User Interactions', () {
      testWidgets('should show clear cache dialog when button is tapped', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        final clearButton = find.text('Clear storage');
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Clear Storage?'), findsOneWidget); // Note: "?" is appended in code
        expect(find.textContaining('5 files'), findsOneWidget);
        // Note: "10.50 MB" appears in both the summary and dialog, so use findAtLeastNWidgets
        expect(find.textContaining('10.50 MB'), findsAtLeastNWidgets(1));
      });

      testWidgets('should not clear cache when dialog is cancelled', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        final clearButton = find.text('Clear storage');
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Tap cancel button
        final cancelButton = find.text('Cancel');
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Verify dialog is dismissed
        expect(find.byType(AlertDialog), findsNothing);

        // Verify clearCache was not called
        verifyNever(() => mockCacheCubit.clearCache());
      });

      testWidgets('should call clearCache when dialog is confirmed', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        final clearButton = find.text('Clear storage');
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Tap clear cache button in dialog
        // Find the button in the dialog (there will be multiple "Clear storage" texts)
        final dialogButtons = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        );
        // The last button should be the "Clear storage" button
        await tester.tap(dialogButtons.last);
        await tester.pumpAndSettle();

        // Verify clearCache was called
        verify(() => mockCacheCubit.clearCache()).called(1);
      });
    });

    group('Information Display', () {
      testWidgets('should display cache description text', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        // The description text should be visible
        expect(find.textContaining('Stored files allow'), findsOneWidget);
      });

      testWidgets('should display cache removal info with constants', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        // Should contain the stale period (365 days) and max objects (5000)
        expect(find.textContaining('365'), findsOneWidget);
        expect(find.textContaining('2000'), findsOneWidget);
      });
    });

    group('Layout and Styling', () {
      testWidgets('should have correct card margins', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        final cards = tester.widgetList<Card>(find.byType(Card)).toList();
        expect(cards.length, 2);

        // Summary card should have all margins
        final summaryCard = cards.first;
        expect(summaryCard.margin, const EdgeInsets.all(16.0));

        // Info card should have horizontal margins
        final infoCard = cards.last;
        expect(
          infoCard.margin,
          const EdgeInsets.symmetric(horizontal: 16.0),
        );
      });

      testWidgets('should display clear cache button with correct icon', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        // Verify button and icon are present
        expect(find.text('Clear storage'), findsOneWidget);
        expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
      });

      testWidgets('should display icons with correct size', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 5, sizeInMB: 10.5),
          ),
        );

        final fileIcon = tester.widget<Icon>(find.byIcon(Icons.file_present));
        expect(fileIcon.size, 32.0);

        final storageIcon = tester.widget<Icon>(find.byIcon(Icons.storage));
        expect(storageIcon.size, 32.0);
      });
    });

    group('State Transitions', () {
      testWidgets('should display loading indicator when in loading state', (tester) async {
        await tester.pumpWidget(createTestWidget(initialState: const CacheLoading()));
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('should display cache info when in loaded state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const CacheLoaded(totalFiles: 10, sizeInMB: 5.5),
          ),
        );

        expect(find.text('10'), findsOneWidget);
        expect(find.text('5.50 MB'), findsOneWidget);
      });
    });
  });
}
