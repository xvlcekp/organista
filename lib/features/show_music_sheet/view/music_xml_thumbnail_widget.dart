import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show CacheManager;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/sheet_load_error.dart';

/// Thumbnail of a MusicXML sheet: its sequence number, since rendering the score would be too heavy for a list.
/// The file is still fetched through the cache like the image and PDF thumbnails, so a sheet that is not on the
/// device shows the same error offline and gets cached while online.
class MusicXmlThumbnailWidget extends HookWidget {
  const MusicXmlThumbnailWidget({super.key, required this.fileUrl, this.sequenceId});

  final String fileUrl;
  final int? sequenceId;

  @override
  Widget build(BuildContext context) {
    final cacheManager = context.read<CacheManager>();
    final file = useFuture(useMemoized(() => cacheManager.getSingleFile(fileUrl), [fileUrl]));
    if (file.hasError) {
      return const SheetLoadError(mode: MusicSheetViewMode.thumbnail);
    }

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
