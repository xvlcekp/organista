import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/l10n/app_localizations.dart' show AppLocalizations;
import 'package:organista/l10n/app_localizations_sk.dart';

extension Localization on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this) ?? AppLocalizationsSk();
}
