import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_music_sheet/view/dismissable_title.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TransposeFabOverlay extends HookWidget {
  const TransposeFabOverlay({
    super.key,
    required this.currentTranspose,
    required this.wvc,
  });

  final int currentTranspose;
  final WebViewController wvc;

  static const double _kItemSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final showMenu = useState(false);
    final showTransposition = useState(true);

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
              borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: context.loc.transposeUp,
                    onPressed: () => wvc.runJavaScript('transposeUp()'),
                  ),
                  IconButton(
                    icon: const Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
                    tooltip: context.loc.resetTranspose,
                    onPressed: () => wvc.runJavaScript('resetTranspose()'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: context.loc.transposeDown,
                    onPressed: () => wvc.runJavaScript('transposeDown()'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _kItemSpacing),
          ],
          FloatingActionButton(
            onPressed: () => showMenu.value = !showMenu.value,
            backgroundColor: showMenu.value ? Colors.grey : Theme.of(context).primaryColor,
            child: Icon(showMenu.value ? Icons.close : Icons.tune),
          ),
        ],
      ),
    );
  }
}
