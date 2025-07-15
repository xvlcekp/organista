import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/services/wakelock/wakelock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferencesWithCache _prefs;
  final WakelockService _wakelockService;

  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _showNavigationArrowsKey = 'show_navigation_arrows';
  static const String _keepScreenOnKey = 'keep_screen_on';

  SettingsCubit(
    this._prefs, {
    WakelockService? wakelockService,
  }) : _wakelockService = wakelockService ?? WakelockPlusService(),
       super(
         SettingsState(
           themeMode: ThemeMode.values[_prefs.getInt(_themeKey) ?? 0],
           locale: Locale(_prefs.getString(_languageKey) ?? 'sk'),
           showNavigationArrows: _prefs.getBool(_showNavigationArrowsKey) ?? true,
           keepScreenOn: _prefs.getBool(_keepScreenOnKey) ?? false,
         ),
       ) {
    // Initialize wakelock based on saved preference
    _initializeWakelock();
  }

  void _initializeWakelock() async {
    try {
      if (state.keepScreenOn) {
        await _wakelockService.enable();
      } else {
        await _wakelockService.disable();
      }
    } catch (e) {
      logger.i("Wakelock initialization failed $e");
      // Handle wakelock errors gracefully (e.g., in tests or unsupported platforms)
    }
  }

  void changeTheme(ThemeMode themeMode) {
    _prefs.setInt(_themeKey, themeMode.index);
    emit(state.copyWith(themeMode: themeMode));
  }

  void changeLanguage(Locale locale) {
    _prefs.setString(_languageKey, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  void changeShowNavigationArrows(bool showArrows) {
    _prefs.setBool(_showNavigationArrowsKey, showArrows);
    emit(state.copyWith(showNavigationArrows: showArrows));
  }

  Future<void> changeKeepScreenOn(bool keepScreenOn) async {
    await _prefs.setBool(_keepScreenOnKey, keepScreenOn);

    // Update wakelock based on the new setting
    try {
      if (keepScreenOn) {
        await _wakelockService.enable();
      } else {
        await _wakelockService.disable();
      }
    } catch (e) {
      logger.e('Error changing keep screen on', error: e);
    }

    emit(state.copyWith(keepScreenOn: keepScreenOn));
  }

  // Getters for testing
  @visibleForTesting
  SharedPreferencesWithCache get prefs => _prefs;

  @visibleForTesting
  WakelockService get wakelockService => _wakelockService;
}
