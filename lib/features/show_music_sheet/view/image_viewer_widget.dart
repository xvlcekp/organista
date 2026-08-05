import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerWidget extends StatelessWidget {
  const ImageViewerWidget({super.key, required this.source, required this.mode});

  final MusicSheetSource source;
  final MusicSheetViewMode mode;

  static const int _previewCacheWidth = 500;
  static const int _thumbnailCacheWidth = 75;
  static const double _maxScaleMultiplier = 3.0;

  @override
  Widget build(BuildContext context) {
    if (mode == MusicSheetViewMode.full) {
      return PhotoView(
        imageProvider: switch (source) {
          MusicSheetUrlSource(:final musicSheet) => CachedNetworkImageProvider(
            musicSheet.fileUrl,
            cacheManager: context.read<CacheManager>(),
          ),
          MusicSheetBytesSource(:final bytes) => MemoryImage(bytes),
        },
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.contained * _maxScaleMultiplier,
        initialScale: PhotoViewComputedScale.contained,
        loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      );
    }

    final memCacheWidth = mode == MusicSheetViewMode.thumbnail ? _thumbnailCacheWidth : _previewCacheWidth;
    final filterQuality = mode == MusicSheetViewMode.thumbnail ? FilterQuality.low : FilterQuality.medium;

    return switch (source) {
      MusicSheetUrlSource(:final musicSheet) => CachedNetworkImage(
        imageUrl: musicSheet.fileUrl,
        cacheManager: context.read<CacheManager>(),
        memCacheWidth: memCacheWidth,
        fit: BoxFit.contain,
        filterQuality: filterQuality,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
      ),
      MusicSheetBytesSource(:final bytes) => Image.memory(
        bytes,
        fit: BoxFit.contain,
        filterQuality: filterQuality,
      ),
    };
  }
}
