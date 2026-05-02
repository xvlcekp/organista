import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_music_sheet/view/dismissable_title.dart';
import 'package:organista/features/show_music_sheet/view/lyrics_row.dart';
import 'package:organista/features/show_music_sheet/view/stepper_row.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicXmlControlsOverlay extends HookWidget {
  const MusicXmlControlsOverlay({
    super.key,
    required this.currentTranspose,
    required this.currentElongationFactor,
    required this.wvc,
  });

  final int currentTranspose;
  final double currentElongationFactor;
  final WebViewController wvc;

  static const double _kItemSpacing = 8.0;
  static const double _kOverlayElevation = 5.0;

  @override
  Widget build(BuildContext context) {
    final showMenu = useState(false);
    final showTransposition = useState(true);
    final lyricsVisible = useState(true);
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      right: AppTheme.symmetricOverlayPadding,
      bottom: AppTheme.symmetricOverlayPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (currentTranspose != 0 && showTransposition.value)
            Container(
              margin: const EdgeInsets.only(bottom: _kItemSpacing),
              child: DismissableTitle(
                title: context.loc.transposeLabel('${currentTranspose > 0 ? '+' : ''}$currentTranspose'),
                onDismiss: () => showTransposition.value = false,
              ),
            ),
          if (showMenu.value) ...[
            Material(
              elevation: _kOverlayElevation,
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
              color: colorScheme.surface,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StepperRow(
                      icon: Icons.music_note,
                      value: '${currentTranspose > 0 ? '+' : ''}$currentTranspose',
                      onDecrease: () => wvc.runJavaScript('transposeDown()'),
                      onIncrease: () => wvc.runJavaScript('transposeUp()'),
                      onReset: () => wvc.runJavaScript('resetTranspose()'),
                      colorScheme: colorScheme,
                    ),
                    const Divider(height: 1),
                    StepperRow(
                      icon: Icons.compress,
                      value: currentElongationFactor.toStringAsFixed(1),
                      onDecrease: () => wvc.runJavaScript('elongationFactorDown()'),
                      onIncrease: () => wvc.runJavaScript('elongationFactorUp()'),
                      onReset: () => wvc.runJavaScript('resetElongationFactor()'),
                      colorScheme: colorScheme,
                    ),
                    const Divider(height: 1),
                    LyricsRow(
                      lyricsVisible: lyricsVisible.value,
                      label: lyricsVisible.value ? context.loc.hideLyrics : context.loc.showLyrics,
                      onToggle: () {
                        lyricsVisible.value = !lyricsVisible.value;
                        wvc.runJavaScript('toggleLyrics()');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _kItemSpacing),
          ],
          FloatingActionButton(
            onPressed: () => showMenu.value = !showMenu.value,
            backgroundColor: showMenu.value ? colorScheme.surfaceContainerHighest : colorScheme.primary,
            foregroundColor: showMenu.value ? colorScheme.onSurface : colorScheme.onPrimary,
            child: Icon(showMenu.value ? Icons.close : Icons.tune),
          ),
        ],
      ),
    );
  }
}
