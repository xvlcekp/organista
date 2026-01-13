import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/show_music_sheet/view/zoomable_music_sheet_viewer.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:pdfx/pdfx.dart';
import 'package:organista/features/show_music_sheet/view/pdf_title_overlay.dart';
import 'package:organista/features/show_music_sheet/view/pdf_page_counter.dart';
import 'package:organista/features/show_music_sheet/view/pdf_navigation_arrows.dart';

class PdfFullView extends HookWidget {
  final MusicSheet musicSheet;
  final PdfController controller;

  const PdfFullView({
    super.key,
    required this.musicSheet,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final showTitle = useState(true);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        return ZoomableMusicSheetViewer(
          child: Stack(
            children: [
              Positioned.fill(
                child: PdfView(
                  controller: controller,
                  scrollDirection: Axis.vertical,
                ),
              ),
              if (showTitle.value)
                PdfTitleOverlay(
                  fileName: musicSheet.fileName,
                  onDismiss: () => showTitle.value = false,
                ),
              PdfPageCounter(controller: controller),
              if (settingsState.showNavigationArrows) PdfNavigationArrows(controller: controller),
            ],
          ),
        );
      },
    );
  }
}
