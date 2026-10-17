import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/show_music_sheet/view/pdf_navigation_touch_area.dart';

/// Tap areas at the top and bottom of the screen that turn the pages of a
/// multi-page sheet. Shown only when the user has enabled the navigation
/// arrows in the settings and the sheet has more than one page; the top area
/// appears from the second page on, the bottom area until the last page.
/// How a page is turned is up to the caller: pdfx jumps the controller, the
/// MusicXML viewer calls into the page's JavaScript.
class PageNavigation extends StatelessWidget {
  const PageNavigation({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        if (!settingsState.showNavigationArrows || pageCount <= 1) {
          return const SizedBox.shrink();
        }
        return Stack(
          children: [
            if (currentPage > 1) PdfNavigationTouchArea(direction: NavigationDirection.top, onTap: onPrevious),
            if (currentPage < pageCount) PdfNavigationTouchArea(direction: NavigationDirection.bottom, onTap: onNext),
          ],
        );
      },
    );
  }
}
