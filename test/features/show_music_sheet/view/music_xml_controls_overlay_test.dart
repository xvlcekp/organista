import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:organista/features/show_music_sheet/view/dismissable_title.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_controls_overlay.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'music_xml_controls_overlay_test.mocks.dart';

@GenerateMocks([PlatformWebViewController])
void main() {
  late MockPlatformWebViewController mockPlatformController;
  late WebViewController wvc;

  setUp(() {
    mockPlatformController = MockPlatformWebViewController();
    when(mockPlatformController.runJavaScript(any)).thenAnswer((_) async {});
    wvc = WebViewController.fromPlatform(mockPlatformController);
  });

  Widget buildWidget({int currentTranspose = 0, double currentElongationFactor = 1.0}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(
          children: [
            MusicXmlControlsOverlay(
              currentTranspose: currentTranspose,
              currentElongationFactor: currentElongationFactor,
              wvc: wvc,
            ),
          ],
        ),
      ),
    );
  }

  group('MusicXmlControlsOverlay', () {
    testWidgets('shows tune icon on FAB initially', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('tapping FAB shows both transpose and elongation factor columns', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.byIcon(Icons.compress), findsOneWidget);
      // Two add buttons: one for transpose, one for spacing
      expect(find.byIcon(Icons.add), findsNWidgets(2));
      // Two remove buttons: one for transpose, one for spacing
      expect(find.byIcon(Icons.remove), findsNWidgets(2));
    });

    testWidgets('tapping FAB again hides the menu', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('shows DismissableTitle when currentTranspose != 0', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: 3));

      expect(find.byType(DismissableTitle), findsOneWidget);
    });

    testWidgets('hides DismissableTitle when currentTranspose == 0', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: 0));

      expect(find.byType(DismissableTitle), findsNothing);
    });

    testWidgets('tapping transpose up calls transposeUp JS', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // First add button is for transpose (stepper row order: transpose, spacing)
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();

      verify(mockPlatformController.runJavaScript('transposeUp()')).called(1);
    });

    testWidgets('tapping transpose down calls transposeDown JS', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // First remove button is for transpose (stepper row order: transpose, spacing)
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump();

      verify(mockPlatformController.runJavaScript('transposeDown()')).called(1);
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

    testWidgets('shows elongation factor value when menu is open', (tester) async {
      await tester.pumpWidget(buildWidget(currentElongationFactor: 1.0));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('1.0'), findsOneWidget);
    });

    testWidgets('shows updated elongation factor value', (tester) async {
      await tester.pumpWidget(buildWidget(currentElongationFactor: 1.4));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('1.4'), findsOneWidget);
    });

    testWidgets('shows max elongation factor value', (tester) async {
      await tester.pumpWidget(buildWidget(currentElongationFactor: 2.2));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('2.2'), findsOneWidget);
    });

    testWidgets('tapping transpose value resets transpose to 0', (tester) async {
      await tester.pumpWidget(buildWidget(currentTranspose: 3));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // First text matching '+3' is inside the stepper row value
      await tester.tap(find.text('+3'));
      await tester.pump();

      verify(mockPlatformController.runJavaScript('resetTranspose()')).called(1);
    });

    testWidgets('tapping elongation factor value resets to default', (tester) async {
      await tester.pumpWidget(buildWidget(currentElongationFactor: 1.4));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      await tester.tap(find.text('1.4'));
      await tester.pump();

      verify(mockPlatformController.runJavaScript('resetElongationFactor()')).called(1);
    });

    testWidgets('tapping elongation factor up calls elongationFactorUp JS', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.last);
      await tester.pump();

      verify(mockPlatformController.runJavaScript('elongationFactorUp()')).called(1);
    });

    testWidgets('tapping elongation factor down calls elongationFactorDown JS', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      final removeButtons = find.byIcon(Icons.remove);
      // Second remove button is for elongation factor
      await tester.tap(removeButtons.last);
      await tester.pump();

      verify(mockPlatformController.runJavaScript('elongationFactorDown()')).called(1);
    });

    testWidgets('shows lyrics icon when menu is open', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.byIcon(Icons.lyrics), findsOneWidget);
      expect(find.byIcon(Icons.lyrics_outlined), findsNothing);
    });

    testWidgets('tapping lyrics button toggles to lyrics_outlined icon', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.lyrics));
      await tester.pump();

      expect(find.byIcon(Icons.lyrics_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lyrics), findsNothing);
    });

    testWidgets('tapping lyrics button again toggles back to lyrics icon', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.lyrics));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.lyrics_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.lyrics), findsOneWidget);
    });

    testWidgets('tapping lyrics button calls toggleLyrics JS', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.lyrics));
      await tester.pump();

      verify(mockPlatformController.runJavaScript('toggleLyrics()')).called(1);
    });
  });
}
