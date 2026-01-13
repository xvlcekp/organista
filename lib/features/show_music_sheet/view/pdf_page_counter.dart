import 'package:flutter/material.dart';
import 'package:organista/config/app_theme.dart';
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.onSurface,
          borderRadius: BorderRadius.circular(AppTheme.inputBorderRadius),
        ),
        child: PdfPageNumber(
          controller: controller,
          builder: (_, state, loadingState, pagesCount) => DefaultTextStyle(
            style: const TextStyle(fontSize: 18, color: Colors.white),
            child: Text('${controller.page}/${pagesCount ?? 0}'),
          ),
        ),
      ),
    );
  }
}
