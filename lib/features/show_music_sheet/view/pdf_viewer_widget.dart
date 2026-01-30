import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/extensions/hex_color.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/pdf_page_counter.dart';
import 'package:organista/features/show_music_sheet/view/pdf_navigation_arrows.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:pdfx/pdfx.dart';

import 'package:organista/features/show_music_sheet/hooks/pdf_load_result.dart';

class PdfViewerWidget extends HookWidget {
  final MusicSheet musicSheet;
  final MusicSheetViewMode mode;
  final Color backgroundColor = Colors.white;

  /// Quality for PDF full rendering
  static const double fullQuality = 2.0;

  /// Quality for PDF preview rendering
  static const double previewQuality = 1.0;

  /// Quality for PDF thumbnail rendering
  static const double thumbnailQuality = 0.5;

  const PdfViewerWidget({
    super.key,
    required this.musicSheet,
    this.mode = MusicSheetViewMode.full,
  });

  @override
  Widget build(BuildContext context) {
    final loadResult = usePdfDocument(musicSheet);

    if (loadResult.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadResult.hasError || loadResult.controller == null) {
      return const Center(child: Icon(Icons.warning_rounded, color: Colors.red));
    }

    final pdfController = loadResult.controller!;

    final qualityMultiplier = switch (mode) {
      MusicSheetViewMode.full => fullQuality,
      MusicSheetViewMode.thumbnail => thumbnailQuality,
      MusicSheetViewMode.preview => previewQuality,
    };

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return Stack(
          children: [
            PdfView(
              controller: pdfController,
              scrollDirection: Axis.vertical,
              renderer: (PdfPage page) {
                return page.render(
                  width: page.width * qualityMultiplier,
                  height: page.height * qualityMultiplier,
                  format: PdfPageImageFormat.jpeg,
                  backgroundColor: backgroundColor.toHex(),
                );
              },
            ),
            if (mode == MusicSheetViewMode.full) PdfPageCounter(controller: pdfController),
            if (mode == MusicSheetViewMode.full && settingsState.showNavigationArrows)
              PdfNavigationArrows(controller: pdfController),
          ],
        );
      },
    );
  }
}
