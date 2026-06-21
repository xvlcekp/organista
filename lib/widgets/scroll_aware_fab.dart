import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/config/app_theme.dart';

class ScrollAwareFab extends HookWidget {
  const ScrollAwareFab({
    super.key,
    required this.scrollController,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
  });

  final ScrollController scrollController;
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  static const _height = 56.0;
  static const _borderRadius = 28.0;
  static const _horizontalPadding = 16.0;
  static const _iconLabelGap = 8.0;
  static const _elevation = 6.0;
  static const _shadowAlpha = 0.4;
  static const _animationDurationMs = 280;

  @override
  Widget build(BuildContext context) {
    final isExtended = useState(true);

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        final shouldBeExtended = scrollController.offset <= AppTheme.fabCollapseThreshold;
        if (isExtended.value != shouldBeExtended) {
          isExtended.value = shouldBeExtended;
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary;
    final fg = theme.colorScheme.onPrimary;
    const duration = Duration(milliseconds: _animationDurationMs);
    const curve = Curves.easeInOutCubic;

    return Material(
      color: bg,
      elevation: _elevation,
      shadowColor: bg.withValues(alpha: _shadowAlpha),
      borderRadius: BorderRadius.circular(_borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg),
                ClipRect(
                  child: AnimatedAlign(
                    duration: duration,
                    curve: curve,
                    alignment: Alignment.centerLeft,
                    widthFactor: isExtended.value ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: _iconLabelGap),
                      child: AnimatedOpacity(
                        duration: duration,
                        opacity: isExtended.value ? 1.0 : 0.0,
                        curve: curve,
                        child: Text(
                          label,
                          style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
