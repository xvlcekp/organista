import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that handles gallery-specific keyboard shortcuts
class GalleryShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const GalleryShortcuts({
    super.key,
    required this.child,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowRight): NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): PreviousPageIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NextPageIntent: CallbackAction<NextPageIntent>(onInvoke: (_) => onNext()),
          PreviousPageIntent: CallbackAction<PreviousPageIntent>(onInvoke: (_) => onPrevious()),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class NextPageIntent extends Intent {
  const NextPageIntent();
}

class PreviousPageIntent extends Intent {
  const PreviousPageIntent();
}
