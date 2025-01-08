import 'dart:typed_data';
import 'package:flutter/material.dart';

class UploadedMusicSheetImageView extends StatelessWidget {
  const UploadedMusicSheetImageView({
    super.key,
    required this.image,
  });

  final Uint8List image;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.scale(
        alignment: Alignment.topCenter, // Align the top of the image
        scale: 4.0, // Scale the image to zoom in
        child: Image.memory(
          image,
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }
}
