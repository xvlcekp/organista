import 'package:flutter/material.dart';
import 'package:organista/features/show_music_sheet/view/pdf_navigation_touch_area.dart';
import 'package:pdfx/pdfx.dart';

class PdfNavigationArrows extends StatelessWidget {
  final PdfController controller;

  const PdfNavigationArrows({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return PdfPageNumber(
      controller: controller,
      builder: (_, state, loadingState, pagesCount) {
        if (pagesCount == null || pagesCount <= 1) {
          return const SizedBox.shrink();
        }

        final currentPage = controller.page;
        return Stack(
          children: [
            if (currentPage > 1)
              PdfNavigationTouchArea(
                direction: NavigationDirection.top,
                onTap: () => controller.jumpToPage(currentPage - 1),
              ),
            if (currentPage < pagesCount)
              PdfNavigationTouchArea(
                direction: NavigationDirection.bottom,
                onTap: () => controller.jumpToPage(currentPage + 1),
              ),
          ],
        );
      },
    );
  }
}
