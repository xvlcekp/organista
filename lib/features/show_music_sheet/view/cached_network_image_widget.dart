import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
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

  static const int _previewCacheWidth = 500;
  static const int _thumbnailCacheWidth = 75;
  static const double _maxScaleMultiplier = 3.0;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      MusicSheetViewMode.full => _buildImage(context),
      MusicSheetViewMode.thumbnail => _buildThumbnailImage(context),
      MusicSheetViewMode.preview => _buildPreviewImage(context),
    };
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
      child: _buildImage(
        context,
        memCacheWidth: _previewCacheWidth,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildThumbnailImage(BuildContext context) {
    return _buildImage(
      context,
      memCacheWidth: _thumbnailCacheWidth,
      filterQuality: FilterQuality.low,
    );
  }

  Widget _buildImage(
    BuildContext context, {
    int? memCacheWidth,
    FilterQuality filterQuality = FilterQuality.high,
  }) {
    final cacheManager = context.read<CacheManager>();

    return PhotoView(
      imageProvider: CachedNetworkImageProvider(
        musicSheet.fileUrl,
        cacheManager: cacheManager,
        maxWidth: memCacheWidth,
      ),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * _maxScaleMultiplier,
      initialScale: PhotoViewComputedScale.contained,
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
      filterQuality: filterQuality,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
    );
  }
}
