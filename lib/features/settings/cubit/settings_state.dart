import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final bool showNavigationArrows;
  final bool keepScreenOn;

  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.showNavigationArrows,
    required this.keepScreenOn,
  });

  @override
  List<Object> get props => [themeMode, locale, showNavigationArrows, keepScreenOn];

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? showNavigationArrows,
    bool? keepScreenOn,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      showNavigationArrows: showNavigationArrows ?? this.showNavigationArrows,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }

  @override
  String toString() {
    return 'SettingsState(themeMode: $themeMode, locale: $locale, '
        'showNavigationArrows: $showNavigationArrows, keepScreenOn: $keepScreenOn)';
  }
}
