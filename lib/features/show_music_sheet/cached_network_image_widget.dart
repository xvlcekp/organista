import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:photo_view/photo_view.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  const CachedNetworkImageWidget({
    super.key,
    required this.musicSheet,
    required this.mode,
  });

  final MusicSheet musicSheet;
  final MusicSheetViewMode mode;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      MusicSheetViewMode.full => getFullImageView(),
      MusicSheetViewMode.thumbnail => getThumbnailImageView(),
      MusicSheetViewMode.preview => getPreviewImage(context),
    };
  }

  Widget getFullImageView() {
    return PhotoView.customChild(
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.contained * 3.0,
        initialScale: PhotoViewComputedScale.contained * 1.0,
        child: CachedNetworkImage(
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          imageUrl: musicSheet.fileUrl,
          fit: BoxFit.fitHeight,
        ));
  }

  Widget getPreviewImage(BuildContext context) {
    return GestureDetector(
        onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CachedNetworkImageWidget(
                  musicSheet: musicSheet,
                  mode: MusicSheetViewMode.full,
                ),
              ),
            ),
        child: CachedNetworkImage(
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
          imageUrl: musicSheet.fileUrl,
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.high,
          memCacheWidth: 500,
        ));
  }

  Widget getThumbnailImageView() {
    return CachedNetworkImage(
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      imageUrl: musicSheet.fileUrl,
      fit: BoxFit.fitHeight,
      filterQuality: FilterQuality.low,
      memCacheWidth: 75,
    );
  }
}
