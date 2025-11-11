import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final int themeModeIndex;
  final String localeString;
  final bool showNavigationArrows;
  final bool keepScreenOn;

  const SettingsState({
    required this.themeModeIndex,
    required this.localeString,
    required this.showNavigationArrows,
    required this.keepScreenOn,
  });

  // Convenience getters for UI layer
  ThemeMode get themeMode => ThemeMode.values[themeModeIndex];
  Locale get locale => Locale(localeString);

  @override
  List<Object> get props => [themeModeIndex, localeString, showNavigationArrows, keepScreenOn];

  SettingsState copyWith({
    int? themeModeIndex,
    String? localeString,
    bool? showNavigationArrows,
    bool? keepScreenOn,
  }) {
    return SettingsState(
      themeModeIndex: themeModeIndex ?? this.themeModeIndex,
      localeString: localeString ?? this.localeString,
      showNavigationArrows: showNavigationArrows ?? this.showNavigationArrows,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }

  @override
  String toString() {
    return 'SettingsState(themeModeIndex: $themeModeIndex, localeString: $localeString, '
        'showNavigationArrows: $showNavigationArrows, keepScreenOn: $keepScreenOn)';
  }
}
