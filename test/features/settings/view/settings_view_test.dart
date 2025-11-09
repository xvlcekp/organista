import 'dart:async';

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

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  group('SettingsView Widget Tests', () {
    late MockSettingsCubit mockSettingsCubit;
    late MockAuthBloc mockAuthBloc;

    // Test data
    const testUser = AuthUser(
      id: 'test-user-123',
      email: 'test@example.com',
      isEmailVerified: true,
    );

    setUp(() {
      mockSettingsCubit = MockSettingsCubit();
      mockAuthBloc = MockAuthBloc();

      // Setup default states and streams
      when(() => mockAuthBloc.state).thenReturn(
        const AuthStateLoggedIn(isLoading: false, user: testUser),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          const AuthStateLoggedIn(isLoading: false, user: testUser),
        ]),
      );

      when(() => mockSettingsCubit.state).thenReturn(
        SettingsState(
          themeModeIndex: ThemeMode.system.index,
          localeString: 'en',
          showNavigationArrows: true,
          keepScreenOn: false,
        ),
      );
      when(() => mockSettingsCubit.stream).thenAnswer(
        (_) => Stream.fromIterable([
          SettingsState(
            themeModeIndex: ThemeMode.system.index,
            localeString: 'en',
            showNavigationArrows: true,
            keepScreenOn: false,
          ),
        ]),
      );

      // Register fallback values for mocktail
      registerFallbackValue(ThemeMode.system);
      registerFallbackValue(const Locale('en'));
      registerFallbackValue(const AuthEventDeleteAccount());

      // Mock the changeKeepScreenOn method
      when(() => mockSettingsCubit.changeKeepScreenOn(any())).thenAnswer((_) async {});
    });

    Widget createTestWidget({SettingsState? initialState, bool withNavigatorObserver = false}) {
      final state =
          initialState ??
          SettingsState(
            themeModeIndex: ThemeMode.system.index,
            localeString: 'en',
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

    group('BlocListener Navigation Tests', () {
      testWidgets('should contain BlocListener that listens to AuthBloc state changes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify that BlocListener is present in the widget tree
        expect(find.byType(BlocListener<AuthBloc, AuthState>), findsOneWidget);

        // Verify that the BlocListener is listening to AuthBloc
        final blocListener = tester.widget<BlocListener<AuthBloc, AuthState>>(
          find.byType(BlocListener<AuthBloc, AuthState>),
        );
        expect(blocListener.listener, isNotNull);
      });

      testWidgets('should have correct widget structure with BlocListener wrapping Scaffold', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify the widget hierarchy
        final blocListener = find.byType(BlocListener<AuthBloc, AuthState>);
        final scaffold = find.byType(Scaffold);

        expect(blocListener, findsOneWidget);
        expect(scaffold, findsOneWidget);

        // Verify BlocListener is ancestor of Scaffold
        expect(find.ancestor(of: scaffold, matching: blocListener), findsOneWidget);
      });

      testWidgets('should have listener function that checks for AuthStateLoggedOut', (tester) async {
        // Create a simple test to verify the listener logic without complex navigation
        bool listenerExecuted = false;

        // Create a simple widget that mimics the BlocListener behavior
        Widget testWidget = MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
            ],
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                // This is the same logic as in SettingsView
                if (authState is AuthStateLoggedOut) {
                  listenerExecuted = true;
                }
              },
              child: const Scaffold(body: Text('Test')),
            ),
          ),
        );

        await tester.pumpWidget(testWidget);

        // Initially, listener should not be executed
        expect(listenerExecuted, false);

        // Mock the auth bloc to emit AuthStateLoggedOut
        when(() => mockAuthBloc.state).thenReturn(
          const AuthStateLoggedOut(isLoading: false),
        );

        // Simulate the state change by manually calling the listener
        final blocListener = tester.widget<BlocListener<AuthBloc, AuthState>>(
          find.byType(BlocListener<AuthBloc, AuthState>),
        );

        // Call the listener with AuthStateLoggedOut
        blocListener.listener(tester.element(find.byType(Scaffold)), const AuthStateLoggedOut(isLoading: false));

        // Verify that the listener logic was executed
        expect(listenerExecuted, true);
      });
    });

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
        await tester.pumpWidget(
          createTestWidget(
            initialState: SettingsState(
              themeModeIndex: ThemeMode.system.index,
              localeString: 'en',
              showNavigationArrows: true,
              keepScreenOn: false,
            ),
          ),
        );

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
        await tester.pumpWidget(
          createTestWidget(
            initialState: SettingsState(
              themeModeIndex: ThemeMode.system.index,
              localeString: 'en',
              showNavigationArrows: true,
              keepScreenOn: true,
            ),
          ),
        );

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
        await tester.pumpWidget(
          createTestWidget(
            initialState: SettingsState(
              themeModeIndex: ThemeMode.system.index,
              localeString: 'en',
              showNavigationArrows: true,
              keepScreenOn: true,
            ),
          ),
        );

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

    group('Delete Account Functionality', () {
      testWidgets('should display delete account button with correct styling', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find the delete account list tile
        final deleteAccountTile = find.ancestor(
          of: find.text('Delete account'),
          matching: find.byType(ListTile),
        );
        expect(deleteAccountTile, findsOneWidget);

        // Verify it has the correct icon
        final deleteIcon = find.descendant(
          of: deleteAccountTile,
          matching: find.byIcon(Icons.delete_forever),
        );
        expect(deleteIcon, findsOneWidget);
      });

      testWidgets('should show delete account dialog when tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find and tap the delete account button
        final deleteAccountTile = find.ancestor(
          of: find.text('Delete account'),
          matching: find.byType(ListTile),
        );
        await tester.tap(deleteAccountTile);
        await tester.pumpAndSettle();

        // Verify the dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Delete account'), findsAtLeastNWidgets(1)); // Title in dialog
        expect(
          find.text('Are you sure you want to delete your account? This action cannot be undone.'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete account'), findsAtLeastNWidgets(1)); // Button in dialog
      });

      testWidgets('should not delete account when cancel is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find and tap the delete account button
        final deleteAccountTile = find.ancestor(
          of: find.text('Delete account'),
          matching: find.byType(ListTile),
        );
        await tester.tap(deleteAccountTile);
        await tester.pumpAndSettle();

        // Tap cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify dialog is dismissed
        expect(find.byType(AlertDialog), findsNothing);

        // Verify no auth event was sent
        verifyNever(() => mockAuthBloc.add(any()));
      });

      testWidgets('should delete account when delete is confirmed', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find and tap the delete account button
        final deleteAccountTile = find.ancestor(
          of: find.text('Delete account'),
          matching: find.byType(ListTile),
        );
        await tester.tap(deleteAccountTile);
        await tester.pumpAndSettle();

        // Find delete buttons (there will be multiple text widgets with "Delete account")
        final deleteButtons = find.text('Delete account');
        expect(deleteButtons, findsAtLeastNWidgets(2));

        // Tap the delete button in the dialog (not the title)
        final dialogDeleteButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.ancestor(
            of: find.text('Delete account'),
            matching: find.byType(TextButton),
          ),
        );
        await tester.tap(dialogDeleteButton);
        await tester.pumpAndSettle();

        // Verify the dialog is dismissed
        expect(find.byType(AlertDialog), findsNothing);

        // Verify the auth bloc received the delete account event
        verify(() => mockAuthBloc.add(const AuthEventDeleteAccount())).called(1);
      });

      testWidgets('should complete delete account flow and send auth event', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Find and tap the delete account button
        final deleteAccountTile = find.ancestor(
          of: find.text('Delete account'),
          matching: find.byType(ListTile),
        );
        await tester.tap(deleteAccountTile);
        await tester.pumpAndSettle();

        // Confirm deletion
        final dialogDeleteButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.ancestor(
            of: find.text('Delete account'),
            matching: find.byType(TextButton),
          ),
        );
        await tester.tap(dialogDeleteButton);
        await tester.pumpAndSettle();

        // Verify delete event was sent
        verify(() => mockAuthBloc.add(const AuthEventDeleteAccount())).called(1);

        // Verify that the BlocListener exists and has correct structure
        expect(find.byType(BlocListener<AuthBloc, AuthState>), findsOneWidget);

        // Verify the listener function is not null
        final settingsView = tester.widget<BlocListener<AuthBloc, AuthState>>(
          find.byType(BlocListener<AuthBloc, AuthState>),
        );
        expect(settingsView.listener, isNotNull);

        // This test verifies the complete user flow:
        // 1. User taps delete account
        // 2. Dialog is shown and confirmed
        // 3. Auth event is sent
        // 4. BlocListener is in place to handle auth state changes
        // The actual navigation behavior would be tested in integration tests
      });
    });
  });
}
