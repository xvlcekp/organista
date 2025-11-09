import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_event.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/services/wakelock/wakelock_service.dart';

// Mock classes
class MockSharedPreferences extends Mock implements SharedPreferencesWithCache {}

class MockWakelockService extends Mock implements WakelockService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsEvent Equatable', () {
    test('SettingsEventChangeTheme supports value equality', () {
      final event1 = SettingsEventChangeTheme(ThemeMode.dark);
      final event2 = SettingsEventChangeTheme(ThemeMode.dark);
      final event3 = SettingsEventChangeTheme(ThemeMode.light);

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('SettingsEventChangeLanguage supports value equality', () {
      final event1 = SettingsEventChangeLanguage(const Locale('en'));
      final event2 = SettingsEventChangeLanguage(const Locale('en'));
      final event3 = SettingsEventChangeLanguage(const Locale('sk'));

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('SettingsEventChangeShowNavigationArrows supports value equality', () {
      final event1 = SettingsEventChangeShowNavigationArrows(true);
      final event2 = SettingsEventChangeShowNavigationArrows(true);
      final event3 = SettingsEventChangeShowNavigationArrows(false);

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('SettingsEventChangeKeepScreenOn supports value equality', () {
      final event1 = SettingsEventChangeKeepScreenOn(true);
      final event2 = SettingsEventChangeKeepScreenOn(true);
      final event3 = SettingsEventChangeKeepScreenOn(false);

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });
  });

  group('SettingsState', () {
    test('supports value equality', () {
      final state1 = SettingsState(
        themeModeIndex: ThemeMode.dark.index,
        localeString: 'en',
        showNavigationArrows: true,
        keepScreenOn: false,
      );

      final state2 = SettingsState(
        themeModeIndex: ThemeMode.dark.index,
        localeString: 'en',
        showNavigationArrows: true,
        keepScreenOn: false,
      );

      expect(state1, equals(state2));
    });

    test('copyWith returns new instance with updated values', () {
      final originalState = SettingsState(
        themeModeIndex: ThemeMode.light.index,
        localeString: 'sk',
        showNavigationArrows: false,
        keepScreenOn: false,
      );

      final newState = originalState.copyWith(
        themeModeIndex: ThemeMode.dark.index,
        keepScreenOn: true,
      );

      expect(newState.themeModeIndex, ThemeMode.dark.index);
      expect(newState.localeString, 'sk'); // unchanged
      expect(newState.showNavigationArrows, false); // unchanged
      expect(newState.keepScreenOn, true);
    });

    test('has correct default values', () {
      final state = SettingsState(
        themeModeIndex: ThemeMode.system.index,
        localeString: 'sk',
        showNavigationArrows: true,
        keepScreenOn: false,
      );

      expect(state.themeModeIndex, ThemeMode.system.index);
      expect(state.localeString, 'sk');
      expect(state.showNavigationArrows, true);
      expect(state.keepScreenOn, false);
    });

    test('should support inequality', () {
      final state1 = SettingsState(
        themeModeIndex: ThemeMode.system.index,
        localeString: 'en',
        showNavigationArrows: true,
        keepScreenOn: false,
      );

      final state2 = SettingsState(
        themeModeIndex: ThemeMode.dark.index,
        localeString: 'en',
        showNavigationArrows: true,
        keepScreenOn: false,
      );

      expect(state1, isNot(equals(state2)));
    });

    test('should support copyWith for keepScreenOn', () {
      final originalState = SettingsState(
        themeModeIndex: ThemeMode.system.index,
        localeString: 'sk',
        showNavigationArrows: true,
        keepScreenOn: false,
      );

      final newState = originalState.copyWith(keepScreenOn: true);

      expect(newState.keepScreenOn, true);
      expect(newState.themeModeIndex, originalState.themeModeIndex);
      expect(newState.localeString, originalState.localeString);
      expect(newState.showNavigationArrows, originalState.showNavigationArrows);
    });

    test('should support copyWith for multiple properties including keepScreenOn', () {
      final originalState = SettingsState(
        themeModeIndex: ThemeMode.system.index,
        localeString: 'sk',
        showNavigationArrows: true,
        keepScreenOn: false,
      );

      final newState = originalState.copyWith(
        keepScreenOn: true,
        themeModeIndex: ThemeMode.dark.index,
        localeString: 'en',
      );

      expect(newState.keepScreenOn, true);
      expect(newState.themeModeIndex, ThemeMode.dark.index);
      expect(newState.localeString, 'en');
      expect(newState.showNavigationArrows, originalState.showNavigationArrows);
    });
  });

  group('SettingsCubit', () {
    late MockSharedPreferences mockPrefs;
    late MockWakelockService mockWakelockService;
    late SettingsCubit settingsCubit;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockWakelockService = MockWakelockService();

      // Setup default SharedPreferences mock responses
      when(() => mockPrefs.getInt('theme_mode')).thenReturn(0);
      when(() => mockPrefs.getString('language_code')).thenReturn('sk');
      when(() => mockPrefs.getBool('show_navigation_arrows')).thenReturn(true);
      when(() => mockPrefs.getBool('keep_screen_on')).thenReturn(false);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      // Setup wakelock service mocks
      when(() => mockWakelockService.enable()).thenAnswer((_) async {});
      when(() => mockWakelockService.disable()).thenAnswer((_) async {});
    });

    tearDown(() {
      settingsCubit.close();
    });

    group('Initialization', () {
      test('should initialize with default values when SharedPreferences is empty', () {
        when(() => mockPrefs.getInt('theme_mode')).thenReturn(null);
        when(() => mockPrefs.getString('language_code')).thenReturn(null);
        when(() => mockPrefs.getBool('show_navigation_arrows')).thenReturn(null);
        when(() => mockPrefs.getBool('keep_screen_on')).thenReturn(null);

        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);

        expect(settingsCubit.state.themeModeIndex, ThemeMode.system.index);
        expect(settingsCubit.state.localeString, 'sk');
        expect(settingsCubit.state.showNavigationArrows, true);
        expect(settingsCubit.state.keepScreenOn, false);

        // Should call disable since keepScreenOn is false
        verify(() => mockWakelockService.disable()).called(1);
      });

      test('should initialize with saved values from SharedPreferences', () {
        when(() => mockPrefs.getInt('theme_mode')).thenReturn(2); // Dark theme
        when(() => mockPrefs.getString('language_code')).thenReturn('en');
        when(() => mockPrefs.getBool('show_navigation_arrows')).thenReturn(false);
        when(() => mockPrefs.getBool('keep_screen_on')).thenReturn(true);

        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);

        expect(settingsCubit.state.themeModeIndex, ThemeMode.dark.index);
        expect(settingsCubit.state.localeString, 'en');
        expect(settingsCubit.state.showNavigationArrows, false);
        expect(settingsCubit.state.keepScreenOn, true);

        // Should call enable since keepScreenOn is true
        verify(() => mockWakelockService.enable()).called(1);
      });

      test('should handle wakelock initialization errors gracefully', () {
        when(() => mockWakelockService.disable()).thenThrow(Exception('Wakelock error'));

        expect(
          () => SettingsCubit(mockPrefs, wakelockService: mockWakelockService),
          returnsNormally,
        );
      });
    });

    group('Theme Management', () {
      setUp(() {
        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);
      });

      test('should change theme mode and save to preferences', () {
        settingsCubit.changeTheme(ThemeMode.dark.index);

        expect(settingsCubit.state.themeModeIndex, ThemeMode.dark.index);
        verify(() => mockPrefs.setInt('theme_mode', 2)).called(1);
      });

      test('should emit new state when theme changes', () async {
        final states = <SettingsState>[];
        settingsCubit.stream.listen(states.add);

        settingsCubit.changeTheme(ThemeMode.light.index);
        await Future.delayed(Duration.zero); // Allow stream to emit

        expect(states.length, 1);
        expect(states.first.themeModeIndex, ThemeMode.light.index);
        expect(states.first.localeString, 'sk'); // Other values unchanged
        expect(states.first.showNavigationArrows, true); // Other values unchanged
        expect(states.first.keepScreenOn, false); // Other values unchanged
      });
    });

    group('Language Management', () {
      setUp(() {
        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);
      });

      test('should change language and save to preferences', () {
        settingsCubit.changeLanguage('en');

        expect(settingsCubit.state.localeString, 'en');
        verify(() => mockPrefs.setString('language_code', 'en')).called(1);
      });

      test('should emit new state when language changes', () async {
        final states = <SettingsState>[];
        settingsCubit.stream.listen(states.add);

        settingsCubit.changeLanguage('en');
        await Future.delayed(Duration.zero); // Allow stream to emit

        expect(states.length, 1);
        expect(states.first.localeString, 'en');
        expect(states.first.themeModeIndex, ThemeMode.system.index); // Other values unchanged
        expect(states.first.showNavigationArrows, true); // Other values unchanged
        expect(states.first.keepScreenOn, false); // Other values unchanged
      });
    });

    group('Navigation Arrows Management', () {
      setUp(() {
        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);
      });

      test('should change show navigation arrows and save to preferences', () {
        settingsCubit.changeShowNavigationArrows(false);

        expect(settingsCubit.state.showNavigationArrows, false);
        verify(() => mockPrefs.setBool('show_navigation_arrows', false)).called(1);
      });

      test('should emit new state when navigation arrows setting changes', () async {
        final states = <SettingsState>[];
        settingsCubit.stream.listen(states.add);

        settingsCubit.changeShowNavigationArrows(false);
        await Future.delayed(Duration.zero); // Allow stream to emit

        expect(states.length, 1);
        expect(states.first.showNavigationArrows, false);
        expect(states.first.themeModeIndex, ThemeMode.system.index); // Other values unchanged
        expect(states.first.localeString, 'sk'); // Other values unchanged
        expect(states.first.keepScreenOn, false); // Other values unchanged
      });
    });

    group('Keep Screen On Management', () {
      setUp(() {
        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);
      });

      test('should enable keep screen on and save to preferences', () async {
        await settingsCubit.changeKeepScreenOn(true);

        expect(settingsCubit.state.keepScreenOn, true);
        verify(() => mockPrefs.setBool('keep_screen_on', true)).called(1);
        verify(() => mockWakelockService.enable()).called(1);
      });

      test('should disable keep screen on and save to preferences', () async {
        // First enable it
        await settingsCubit.changeKeepScreenOn(true);
        clearInteractions(mockWakelockService);
        clearInteractions(mockPrefs);

        // Then disable it
        await settingsCubit.changeKeepScreenOn(false);

        expect(settingsCubit.state.keepScreenOn, false);
        verify(() => mockPrefs.setBool('keep_screen_on', false)).called(1);
        verify(() => mockWakelockService.disable()).called(1);
      });

      test('should emit new state when keep screen on changes', () async {
        final states = <SettingsState>[];
        settingsCubit.stream.listen(states.add);

        await settingsCubit.changeKeepScreenOn(true);
        await Future.delayed(Duration.zero); // Allow stream to emit

        expect(states.length, 1);
        expect(states.first.keepScreenOn, true);
        expect(states.first.themeModeIndex, ThemeMode.system.index); // Other values unchanged
        expect(states.first.localeString, 'sk'); // Other values unchanged
        expect(states.first.showNavigationArrows, true); // Other values unchanged
      });

      test('should handle wakelock errors gracefully when enabling', () async {
        when(() => mockWakelockService.enable()).thenThrow(Exception('Wakelock error'));

        // The function should complete without throwing, even if logging occurs
        await settingsCubit.changeKeepScreenOn(true);

        expect(settingsCubit.state.keepScreenOn, true);
        verify(() => mockPrefs.setBool('keep_screen_on', true)).called(1);
      });

      test('should handle wakelock errors gracefully when disabling', () async {
        when(() => mockWakelockService.disable()).thenThrow(Exception('Wakelock error'));

        // The function should complete without throwing, even if logging occurs
        await settingsCubit.changeKeepScreenOn(false);

        expect(settingsCubit.state.keepScreenOn, false);
        verify(() => mockPrefs.setBool('keep_screen_on', false)).called(1);
      });
    });

    group('State Persistence', () {
      setUp(() {
        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);
      });

      test('should persist all settings correctly', () async {
        await settingsCubit.changeKeepScreenOn(true);
        settingsCubit.changeTheme(ThemeMode.dark.index);
        settingsCubit.changeLanguage('en');
        settingsCubit.changeShowNavigationArrows(false);

        verify(() => mockPrefs.setBool('keep_screen_on', true)).called(1);
        verify(() => mockPrefs.setInt('theme_mode', 2)).called(1);
        verify(() => mockPrefs.setString('language_code', 'en')).called(1);
        verify(() => mockPrefs.setBool('show_navigation_arrows', false)).called(1);
      });
    });

    group('Getters for Testing', () {
      setUp(() {
        settingsCubit = SettingsCubit(mockPrefs, wakelockService: mockWakelockService);
      });

      test('should expose SharedPreferences for testing', () {
        expect(settingsCubit.prefs, equals(mockPrefs));
      });

      test('should expose WakelockService for testing', () {
        expect(settingsCubit.wakelockService, equals(mockWakelockService));
      });
    });
  });
}
