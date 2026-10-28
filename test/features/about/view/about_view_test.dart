import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/features/about/view/about_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Organista',
      packageName: 'sk.anickaapavol.organista',
      version: '9.9.9',
      buildNumber: '99',
      buildSignature: '',
    );
  });

  Widget buildSubject() => const MaterialApp(
    locale: Locale('sk'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AboutView(),
  );

  testWidgets('shows the guide links, store actions, contact e-mail and version', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Návod na používanie'), findsOneWidget);
    expect(find.text('Často kladené otázky'), findsOneWidget);
    expect(find.text('Novinky'), findsOneWidget);
    expect(find.text('Zdroje nôt'), findsOneWidget);
    expect(find.text('Ohodnotiť aplikáciu'), findsOneWidget);
    expect(find.text('Zdieľať aplikáciu'), findsOneWidget);
    expect(find.text(AppConstants.contactEmail), findsOneWidget);
    expect(find.textContaining('Verzia 9.9.9'), findsOneWidget);
    expect(find.textContaining('2025–${DateTime.now().year} Organista'), findsOneWidget);
  });
}
