import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/managers/persistent_cache_manager.dart';
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
      MusicSheetViewMode.full => _buildFullImageView(),
      MusicSheetViewMode.thumbnail => _buildThumbnailImage(),
      MusicSheetViewMode.preview => _buildPreviewImage(context),
    };
  }

  Widget _buildFullImageView() {
    return PhotoView.customChild(
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * 3.0,
      initialScale: PhotoViewComputedScale.contained,
      child: _buildImage(),
    );
  }

  Widget _buildPreviewImage(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CachedNetworkImageWidget(
            musicSheet: musicSheet,
            mode: MusicSheetViewMode.full,
          ),
        ),
      ),
      child: _buildImage(memCacheWidth: 500, filterQuality: FilterQuality.medium),
    );
  }

  Widget _buildThumbnailImage() {
    return _buildImage(
      memCacheWidth: 75,
      filterQuality: FilterQuality.low,
    );
  }

  Widget _buildImage({int? memCacheWidth, FilterQuality filterQuality = FilterQuality.high}) {
    return CachedNetworkImage(
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageUrl: musicSheet.fileUrl,
      fit: BoxFit.contain,
      memCacheWidth: memCacheWidth,
      filterQuality: filterQuality,
      cacheManager: PersistentCacheManager(),
    );
  }
}
