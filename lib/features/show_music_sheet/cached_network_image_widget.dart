import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/zoomable_music_sheet_viewer.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      MusicSheetViewMode.full => _buildFullImageView(context),
      MusicSheetViewMode.thumbnail => _buildThumbnailImage(context),
      MusicSheetViewMode.preview => _buildPreviewImage(context),
    };
  }

  Widget _buildFullImageView(BuildContext context) {
    return ZoomableMusicSheetViewer(
      child: _buildImage(context),
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
    
    return CachedNetworkImage(
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageUrl: musicSheet.fileUrl,
      fit: BoxFit.contain,
      memCacheWidth: memCacheWidth,
      filterQuality: filterQuality,
      cacheManager: cacheManager,
    );
  }
}
