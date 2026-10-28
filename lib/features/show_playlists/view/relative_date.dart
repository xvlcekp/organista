import 'package:intl/intl.dart';
import 'package:organista/l10n/app_localizations.dart';

/// Days back (counted in calendar days) up to which a date is shown as a weekday name instead of a date.
const int _weekdayLabelMaxDaysAgo = 6;

/// "today", "yesterday", a weekday name for the rest of the past week, otherwise the short date.
/// Compares calendar days, so an edit just before midnight reads "yesterday" a few minutes later.
String formatRelativeDate(DateTime date, {required DateTime now, required AppLocalizations localizations}) {
  final daysAgo = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;
  final locale = localizations.localeName;
  return switch (daysAgo) {
    0 => localizations.today,
    1 => localizations.yesterday,
    > 1 && <= _weekdayLabelMaxDaysAgo => DateFormat.EEEE(locale).format(date),
    _ => DateFormat.yMd(locale).format(date),
  };
}
