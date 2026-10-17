import 'package:flutter/material.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/features/show_music_sheet/view/page_counter_badge.dart';
import 'package:pdfx/pdfx.dart';

class PdfPageCounter extends StatelessWidget {
  final PdfController controller;

  const PdfPageCounter({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppTheme.symmetricOverlayPadding,
      right: AppTheme.symmetricOverlayPadding,
      child: PdfPageNumber(
        controller: controller,
        builder: (_, state, loadingState, pagesCount) => PageCounterBadge(
          currentPage: controller.page,
          pageCount: pagesCount ?? 0,
        ),
      ),
    );
  }
}
