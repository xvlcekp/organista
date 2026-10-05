import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
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

    group('Leaving the screen on logout', () {
      /// The settings screen pushed over a home screen, the way `App` pushes it over the main screen.
      Widget hostWithSettingsPushed(StreamController<AuthState> states) {
        whenListen(
          mockAuthBloc,
          states.stream,
          initialState: const AuthStateLoggedIn(isLoading: false, user: testUser),
        );
        // Providers sit above the MaterialApp so that the pushed settings route can reach them, as in `App`.
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsView()),
                ),
                child: const Text('Home'),
              ),
            ),
          ),
        );
      }

      testWidgets('does not pop itself; the auth listener in App closes pushed screens', (tester) async {
        // Regression: the settings screen used to pop itself on logout while the root listener popped pushed
        // routes as well, so the second pop removed the home route and the app showed a black screen after
        // deleting the account. Exactly one place may pop, and that is the root listener in `App`.
        final states = StreamController<AuthState>();
        addTearDown(states.close);
        await tester.pumpWidget(hostWithSettingsPushed(states));
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsView), findsOneWidget);

        states.add(const AuthStateLoggedOut(isLoading: false));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsView), findsOneWidget);
        expect(find.text('Home'), findsNothing);
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

    group('Signed In As Tile', () {
      testWidgets('should display signed in as label with user email when logged in', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Signed in as'), findsOneWidget);
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('should display account icon in signed in as tile', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final signedInAsTile = find.ancestor(
          of: find.text('Signed in as'),
          matching: find.byType(ListTile),
        );
        expect(signedInAsTile, findsOneWidget);

        final accountIcon = find.descendant(
          of: signedInAsTile,
          matching: find.byIcon(Icons.account_circle),
        );
        expect(accountIcon, findsOneWidget);
      });

      testWidgets('should place signed in as tile after account management section header', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        final accountManagementPosition = tester.getTopLeft(find.text('Account Management'));
        final signedInAsPosition = tester.getTopLeft(find.text('Signed in as'));
        final deleteAccountPosition = tester.getTopLeft(find.text('Delete account'));

        expect(signedInAsPosition.dy, greaterThan(accountManagementPosition.dy));
        expect(signedInAsPosition.dy, lessThan(deleteAccountPosition.dy));
      });

      testWidgets('should not display signed in as tile when user is not logged in', (tester) async {
        // State is logged out and the stream stays silent so the BlocListener
        // never triggers the pop-on-logout navigation.
        when(() => mockAuthBloc.state).thenReturn(
          const AuthStateLoggedOut(isLoading: false),
        );
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Signed in as'), findsNothing);
        expect(find.text('test@example.com'), findsNothing);
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

        // Verify delete event was sent; leaving the screen afterwards is the root navigator reset's job.
        verify(() => mockAuthBloc.add(const AuthEventDeleteAccount())).called(1);

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
