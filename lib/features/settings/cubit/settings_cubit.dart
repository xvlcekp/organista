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

// States
class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  SettingsState({
    required this.themeMode,
    required this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

// Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';

  SettingsCubit(this._prefs)
      : super(SettingsState(
          themeMode: ThemeMode.values[_prefs.getInt(_themeKey) ?? 0],
          locale: Locale(_prefs.getString(_languageKey) ?? 'sk'),
        ));

  void changeTheme(ThemeMode themeMode) {
    _prefs.setInt(_themeKey, themeMode.index);
    emit(state.copyWith(themeMode: themeMode));
  }

  void changeLanguage(Locale locale) {
    _prefs.setString(_languageKey, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }
}
