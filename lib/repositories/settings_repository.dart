import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing app settings persistence using SharedPreferences
class SettingsRepository {
  final SharedPreferencesWithCache _prefs;

  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _showNavigationArrowsKey = 'show_navigation_arrows';
  static const String _keepScreenOnKey = 'keep_screen_on';

  SettingsRepository(this._prefs);

  // Read methods
  int getThemeModeIndex() => _prefs.getInt(_themeKey) ?? 0;

  String getLocaleString() => _prefs.getString(_languageKey) ?? 'sk';

  bool getShowNavigationArrows() => _prefs.getBool(_showNavigationArrowsKey) ?? true;

  bool getKeepScreenOn() => _prefs.getBool(_keepScreenOnKey) ?? false;

  // Write methods
  Future<void> saveThemeModeIndex(int index) async {
    await _prefs.setInt(_themeKey, index);
  }

  Future<void> saveLocaleString(String locale) async {
    await _prefs.setString(_languageKey, locale);
  }

  Future<void> saveShowNavigationArrows(bool value) async {
    await _prefs.setBool(_showNavigationArrowsKey, value);
  }

  Future<void> saveKeepScreenOn(bool value) async {
    await _prefs.setBool(_keepScreenOnKey, value);
  }

  /// Clear all settings (useful for reset or logout scenarios)
  Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(_themeKey),
      _prefs.remove(_languageKey),
      _prefs.remove(_showNavigationArrowsKey),
      _prefs.remove(_keepScreenOnKey),
    ]);
  }
}
