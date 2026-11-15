import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_music_sheet/view/pdf_viewer_widget.dart';
import 'package:pdfx/pdfx.dart';

class MockPdfDocument extends Mock implements PdfDocument {}

void main() {
  /// A document that was closed underneath `PdfView`: every page request fails the way pdfx fails it.
  PdfController controllerForClosedDocument() {
    final document = MockPdfDocument();
    when(() => document.id).thenReturn('closed-document');
    when(() => document.pagesCount).thenReturn(1);
    when(() => document.getPage(any())).thenAnswer((_) async => throw PdfDocumentAlreadyClosedException());
    return PdfController(document: Future.value(document));
  }

  Widget view(
    PdfController controller, {
    required Size size,
    required PdfViewBuilders<DefaultBuilderOptions> builders,
  }) {
    return MaterialApp(
      home: Center(
        child: SizedBox.fromSize(
          size: size,
          child: PdfView(controller: controller, builders: builders),
        ),
      ),
    );
  }

  /// Shows the page, then rebuilds the view the way a rotation does. `PdfView` requests the page again on that
  /// rebuild, and Flutter never listens to the second request because its image provider equals the first one.
  Future<void> showAndRotate(WidgetTester tester, PdfViewBuilders<DefaultBuilderOptions> builders) async {
    final controller = controllerForClosedDocument();
    await tester.pumpWidget(view(controller, size: const Size(300, 400), builders: builders));
    await tester.pump();
    // The page on screen fails too, but that request has a listener: the image stream reports it (silently in
    // release builds, so it never reaches Sentry). Only the request nobody waits for is under test.
    expect(tester.takeException(), isA<PdfDocumentAlreadyClosedException>());

    await tester.pumpWidget(view(controller, size: const Size(400, 300), builders: builders));
    await tester.pump();
    await tester.idle();
  }

  // With pdfx's own page builder this fails with an unhandled PdfDocumentAlreadyClosedException.
  testWidgets('a page request nobody waits for does not fail unhandled when the document is already closed', (
    tester,
  ) async {
    await showAndRotate(tester, PdfViewerWidget.viewBuilders);

    expect(tester.takeException(), isNull);
  });
}
