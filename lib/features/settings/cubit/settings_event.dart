import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SettingsEventChangeTheme extends SettingsEvent {
  final ThemeMode themeMode;
  SettingsEventChangeTheme(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class SettingsEventChangeLanguage extends SettingsEvent {
  final Locale locale;
  SettingsEventChangeLanguage(this.locale);

  @override
  List<Object> get props => [locale];
}

class SettingsEventChangeShowNavigationArrows extends SettingsEvent {
  final bool showArrows;
  SettingsEventChangeShowNavigationArrows(this.showArrows);

  @override
  List<Object> get props => [showArrows];
}

class SettingsEventChangeKeepScreenOn extends SettingsEvent {
  final bool keepScreenOn;
  SettingsEventChangeKeepScreenOn(this.keepScreenOn);

  @override
  List<Object> get props => [keepScreenOn];
}
