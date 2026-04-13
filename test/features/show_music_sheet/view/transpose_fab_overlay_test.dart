import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:organista/features/show_music_sheet/view/dismissable_title.dart';
import 'package:organista/features/show_music_sheet/view/transpose_fab_overlay.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'transpose_fab_overlay_test.mocks.dart';

@GenerateMocks([PlatformWebViewController])
void main() {
  late MockPlatformWebViewController mockPlatformController;
  late WebViewController wvc;

  setUp(() {
    mockPlatformController = MockPlatformWebViewController();
    when(mockPlatformController.runJavaScript(any)).thenAnswer((_) async {});
    wvc = WebViewController.fromPlatform(mockPlatformController);
  });

  Widget buildWidget({int currentTranspose = 0}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(
          children: [
            TransposeFabOverlay(currentTranspose: currentTranspose, wvc: wvc),
          ],
        ),
      ),
    );
  }

  group('TransposeFabOverlay', () {
    testWidgets('shows tune icon on FAB initially', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('tapping FAB shows transpose menu', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('tapping FAB again hides the menu', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('shows DismissableTitle when currentTranspose != 0', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: 3));

      expect(find.byType(DismissableTitle), findsOneWidget);
    });

    testWidgets('hides DismissableTitle when currentTranspose == 0', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: 0));

      expect(find.byType(DismissableTitle), findsNothing);
    });

    testWidgets('tapping DismissableTitle hides transposition label', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: 3));

      expect(find.byType(DismissableTitle), findsOneWidget);
      await tester.tap(find.byType(DismissableTitle));
      await tester.pump();

      expect(find.byType(DismissableTitle), findsNothing);
    });

    testWidgets('shows positive transposition with + prefix', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: 2));

      expect(find.textContaining('+2'), findsOneWidget);
    });

    testWidgets('shows negative transposition without + prefix', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: -3));

      expect(find.textContaining('-3'), findsOneWidget);
      expect(find.textContaining('+-3'), findsNothing);
    });
  });
}
