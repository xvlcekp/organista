import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class SettingsEvent {}

class SettingsEventChangeTheme extends SettingsEvent {
  final ThemeMode themeMode;
  SettingsEventChangeTheme(this.themeMode);
}

class SettingsEventChangeLanguage extends SettingsEvent {
  final Locale locale;
  SettingsEventChangeLanguage(this.locale);
}

class SettingsEventChangeShowNavigationArrows extends SettingsEvent {
  final bool showArrows;
  SettingsEventChangeShowNavigationArrows(this.showArrows);
}

// States
class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final bool showNavigationArrows;

  SettingsState({
    required this.themeMode,
    required this.locale,
    required this.showNavigationArrows,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? showNavigationArrows,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      showNavigationArrows: showNavigationArrows ?? this.showNavigationArrows,
    );
  }
}

// Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _showNavigationArrowsKey = 'show_navigation_arrows';

  SettingsCubit(this._prefs)
      : super(SettingsState(
          themeMode: ThemeMode.values[_prefs.getInt(_themeKey) ?? 0],
          locale: Locale(_prefs.getString(_languageKey) ?? 'sk'),
          showNavigationArrows: _prefs.getBool(_showNavigationArrowsKey) ?? true,
        ));

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
}
