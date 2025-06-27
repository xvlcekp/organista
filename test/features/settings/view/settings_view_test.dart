import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/settings/view/settings_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/services/auth/auth_user.dart';

// Mock classes
class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

class MockAuthBloc extends MockCubit<AuthState> implements AuthBloc {}

void main() {
  group('SettingsView Widget Tests', () {
    late MockSettingsCubit mockSettingsCubit;
    late MockAuthBloc mockAuthBloc;

    // Test data
    final testUser = const AuthUser(
      id: 'test-user-123',
      email: 'test@example.com',
      isEmailVerified: true,
    );

    setUp(() {
      mockSettingsCubit = MockSettingsCubit();
      mockAuthBloc = MockAuthBloc();

      // Setup default states and streams
      when(() => mockAuthBloc.state).thenReturn(
        AuthStateLoggedIn(isLoading: false, user: testUser),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          AuthStateLoggedIn(isLoading: false, user: testUser),
        ]),
      );

      when(() => mockSettingsCubit.state).thenReturn(
        SettingsState(
          themeMode: ThemeMode.system,
          locale: const Locale('en'),
          showNavigationArrows: true,
          keepScreenOn: false,
        ),
      );
      when(() => mockSettingsCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([
          SettingsState(
            themeMode: ThemeMode.system,
            locale: const Locale('en'),
            showNavigationArrows: true,
            keepScreenOn: false,
          ),
        ]),
      );

      // Register fallback values for mocktail
      registerFallbackValue(ThemeMode.system);
      registerFallbackValue(const Locale('en'));

      // Mock the changeKeepScreenOn method
      when(() => mockSettingsCubit.changeKeepScreenOn(any())).thenAnswer((_) async {});
    });

    Widget createTestWidget({SettingsState? initialState}) {
      final state = initialState ??
          SettingsState(
            themeMode: ThemeMode.system,
            locale: const Locale('en'),
            showNavigationArrows: true,
            keepScreenOn: false,
          );
      when(() => mockSettingsCubit.state).thenReturn(state);
      when(() => mockSettingsCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([state]),
      );

      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          ],
          child: const SettingsView(),
        ),
      );
    }

    group('Widget Structure', () {
      testWidgets('should display app bar with correct title', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('should display all setting sections', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('App Settings'), findsOneWidget);
        expect(find.text('Account Management'), findsOneWidget);
      });

      testWidgets('should display all setting options', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('Show navigation arrows'), findsOneWidget);
        expect(find.text('Keep screen on'), findsOneWidget);
        expect(find.text('Delete account'), findsOneWidget);
      });
    });

    group('Keep Screen On Setting', () {
      testWidgets('should display keep screen on setting', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the keep screen on ListTile
        final keepScreenOnTile = find.ancestor(
          of: find.text('Keep screen on'),
          matching: find.byType(ListTile),
        );
        expect(keepScreenOnTile, findsOneWidget);
      });

      testWidgets('should display switch in OFF state when keepScreenOn is false', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: SettingsState(
            themeMode: ThemeMode.system,
            locale: const Locale('en'),
            showNavigationArrows: true,
            keepScreenOn: false,
          ),
        ));

        // Find the switch in the keep screen on setting
        final switches = find.byType(Switch);
        expect(switches, findsNWidgets(2)); // Navigation arrows + Keep screen on

        // Find the keep screen on switch specifically
        final keepScreenOnTile = find.ancestor(
          of: find.text('Keep screen on'),
          matching: find.byType(ListTile),
        );
        final keepScreenOnSwitch = find.descendant(
          of: keepScreenOnTile,
          matching: find.byType(Switch),
        );

        final switchWidget = tester.widget<Switch>(keepScreenOnSwitch);
        expect(switchWidget.value, false);
      });

      testWidgets('should display switch in ON state when keepScreenOn is true', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: SettingsState(
            themeMode: ThemeMode.system,
            locale: const Locale('en'),
            showNavigationArrows: true,
            keepScreenOn: true,
          ),
        ));

        // Find the keep screen on switch specifically
        final keepScreenOnTile = find.ancestor(
          of: find.text('Keep screen on'),
          matching: find.byType(ListTile),
        );
        final keepScreenOnSwitch = find.descendant(
          of: keepScreenOnTile,
          matching: find.byType(Switch),
        );

        final switchWidget = tester.widget<Switch>(keepScreenOnSwitch);
        expect(switchWidget.value, true);
      });

      testWidgets('should call changeKeepScreenOn when switch is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the keep screen on switch
        final keepScreenOnTile = find.ancestor(
          of: find.text('Keep screen on'),
          matching: find.byType(ListTile),
        );
        final keepScreenOnSwitch = find.descendant(
          of: keepScreenOnTile,
          matching: find.byType(Switch),
        );

        // Tap the switch
        await tester.tap(keepScreenOnSwitch);
        await tester.pump();

        // Verify that changeKeepScreenOn was called with true
        verify(() => mockSettingsCubit.changeKeepScreenOn(true)).called(1);
      });

      testWidgets('should call changeKeepScreenOn with false when turning off', (tester) async {
        await tester.pumpWidget(createTestWidget(
          initialState: SettingsState(
            themeMode: ThemeMode.system,
            locale: const Locale('en'),
            showNavigationArrows: true,
            keepScreenOn: true,
          ),
        ));

        // Find the keep screen on switch
        final keepScreenOnTile = find.ancestor(
          of: find.text('Keep screen on'),
          matching: find.byType(ListTile),
        );
        final keepScreenOnSwitch = find.descendant(
          of: keepScreenOnTile,
          matching: find.byType(Switch),
        );

        // Tap the switch to turn it off
        await tester.tap(keepScreenOnSwitch);
        await tester.pump();

        // Verify that changeKeepScreenOn was called with false
        verify(() => mockSettingsCubit.changeKeepScreenOn(false)).called(1);
      });
    });

    group('Other Settings (regression test)', () {
      testWidgets('should display navigation arrows switch', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the navigation arrows switch
        final navArrowsTile = find.ancestor(
          of: find.text('Show navigation arrows'),
          matching: find.byType(ListTile),
        );
        final navArrowsSwitch = find.descendant(
          of: navArrowsTile,
          matching: find.byType(Switch),
        );

        expect(navArrowsSwitch, findsOneWidget);
      });

      testWidgets('should display theme dropdown', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Theme'), findsOneWidget);
        expect(find.byType(DropdownButton<ThemeMode>), findsOneWidget);
      });

      testWidgets('should display language dropdown', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Language'), findsOneWidget);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });
    });

    group('Layout and Positioning', () {
      testWidgets('should place keep screen on setting after navigation arrows', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final listTiles = find.byType(ListTile);
        final listTileWidgets = tester.widgetList<ListTile>(listTiles).toList();

        // Find indices of specific settings
        int navArrowsIndex = -1;
        int keepScreenOnIndex = -1;

        for (int i = 0; i < listTileWidgets.length; i++) {
          final tile = listTileWidgets[i];
          if (tile.title is Text) {
            final titleText = (tile.title as Text).data;
            if (titleText == 'Show navigation arrows') {
              navArrowsIndex = i;
            } else if (titleText == 'Keep screen on') {
              keepScreenOnIndex = i;
            }
          }
        }

        expect(navArrowsIndex, greaterThan(-1));
        expect(keepScreenOnIndex, greaterThan(-1));
        expect(keepScreenOnIndex, greaterThan(navArrowsIndex));
      });

      testWidgets('should place keep screen on setting before account management section', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Scroll to make sure all elements are visible
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        final keepScreenOnFinder = find.text('Keep screen on');
        final accountManagementFinder = find.text('Account Management');

        expect(keepScreenOnFinder, findsOneWidget);
        expect(accountManagementFinder, findsOneWidget);

        final keepScreenOnPosition = tester.getTopLeft(keepScreenOnFinder);
        final accountManagementPosition = tester.getTopLeft(accountManagementFinder);

        expect(keepScreenOnPosition.dy, lessThan(accountManagementPosition.dy));
      });
    });
  });
}
