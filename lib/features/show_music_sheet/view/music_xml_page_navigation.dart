import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/show_music_sheet/view/pdf_navigation_touch_area.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Tap areas at the top and bottom of the screen that turn the pages of a
/// multi-page MusicXML sheet, the same way [PdfNavigationArrows] does for PDFs.
/// The page itself is turned by the JavaScript in `musicXml_display.html`.
class MusicXmlPageNavigation extends StatelessWidget {
  const MusicXmlPageNavigation({
    super.key,
    required this.wvc,
    required this.currentPage,
    required this.pageCount,
  });

  final WebViewController wvc;
  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        if (!settingsState.showNavigationArrows || pageCount <= 1) {
          return const SizedBox.shrink();
        }
        return Stack(
          children: [
            if (currentPage > 1)
              PdfNavigationTouchArea(
                direction: NavigationDirection.top,
                onTap: () => wvc.runJavaScript('prevPage()'),
              ),
            if (currentPage < pageCount)
              PdfNavigationTouchArea(
                direction: NavigationDirection.bottom,
                onTap: () => wvc.runJavaScript('nextPage()'),
              ),
          ],
        );
      },
    );
  }
}
