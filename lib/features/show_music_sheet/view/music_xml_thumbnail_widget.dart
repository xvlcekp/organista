import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class MusicXmlThumbnailWidget extends StatelessWidget {
  const MusicXmlThumbnailWidget({super.key, this.sequenceId});

  final int? sequenceId;

  @override
  Widget build(BuildContext context) {
    final label = (sequenceId != null && sequenceId! > 0) ? '$sequenceId' : 'XML';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: AutoSizeText(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
