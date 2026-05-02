import 'package:flutter/material.dart';

class LyricsRow extends StatelessWidget {
  const LyricsRow({
    super.key,
    required this.lyricsVisible,
    required this.label,
    required this.onToggle,
  });

  final bool lyricsVisible;
  final String label;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: FilledButton.tonal(
        onPressed: onToggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(lyricsVisible ? Icons.lyrics : Icons.lyrics_outlined),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
