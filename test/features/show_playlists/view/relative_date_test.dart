import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:organista/features/show_playlists/view/relative_date.dart';
import 'package:organista/l10n/app_localizations_en.dart';

void main() {
  final localizations = AppLocalizationsEn();
  // A Wednesday, late afternoon.
  final now = DateTime(2026, 10, 28, 16, 45);

  String label(DateTime date) => formatRelativeDate(date, now: now, localizations: localizations);

  group('formatRelativeDate', () {
    // The app gets the locale data from the Material localizations delegate; a plain test has to load it.
    setUpAll(() => initializeDateFormatting('en'));

    test('the same calendar day is "today", however early', () {
      expect(label(DateTime(2026, 10, 28, 0, 5)), 'today');
    });

    test('the previous calendar day is "yesterday" even when less than a day has passed', () {
      expect(label(DateTime(2026, 10, 27, 23, 50)), 'yesterday');
    });

    test('two to six days back show the weekday', () {
      expect(label(DateTime(2026, 10, 26)), 'Monday');
      expect(label(DateTime(2026, 10, 22, 9)), 'Thursday');
    });

    test('a week or more back shows the date', () {
      expect(label(DateTime(2026, 10, 21)), '10/21/2026');
      expect(label(DateTime(2024, 1, 15)), '1/15/2024');
    });

    test('a date in the future shows the date', () {
      expect(label(DateTime(2026, 10, 29)), '10/29/2026');
    });
  });
}
