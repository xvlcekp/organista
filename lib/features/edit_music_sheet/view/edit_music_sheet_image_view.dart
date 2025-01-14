import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

class EditMusicSheetImageView extends StatelessWidget {
  const EditMusicSheetImageView({
    super.key,
    required this.musicSheet,
  });

  final MusicSheet musicSheet;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageUrl: musicSheet.fileUrl,
      fit: BoxFit.fitHeight,
    );
  }
}
