import 'package:flutter/material.dart';
import 'package:organista/features/show_music_sheet/view/page_navigation.dart';
import 'package:pdfx/pdfx.dart';

/// [PageNavigation] driven by a pdfx controller: rebuilds on every page change
/// and turns the pages by jumping the controller.
class PdfPageNavigation extends StatelessWidget {
  const PdfPageNavigation({
    super.key,
    required this.controller,
  });

  final PdfController controller;

  @override
  Widget build(BuildContext context) {
    return PdfPageNumber(
      controller: controller,
      builder: (_, state, loadingState, pagesCount) {
        final currentPage = controller.page;
        return PageNavigation(
          currentPage: currentPage,
          pageCount: pagesCount ?? 1,
          onPrevious: () => controller.jumpToPage(currentPage - 1),
          onNext: () => controller.jumpToPage(currentPage + 1),
        );
      },
    );
  }
}
