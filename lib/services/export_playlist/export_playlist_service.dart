import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

/// Service for exporting playlist music sheets to a single PDF file
class ExportPlaylistService {
  final CacheManager _cacheManager;

  ExportPlaylistService({required CacheManager cacheManager}) : _cacheManager = cacheManager;

  /// Exports all music sheets in the playlist to a single PDF file
  /// Returns the path to the exported PDF file, or null if export failed
  Future<String?> exportPlaylistToPdf({
    required Playlist playlist,
  }) async {
    if (playlist.musicSheets.isEmpty) {
      logger.w('No music sheets to export');
      return null;
    }

    try {
      // Step 1: Download all files to local paths
      final filePaths = await _downloadAllFiles(playlist.musicSheets);

      if (filePaths.isEmpty) {
        logger.e('No files downloaded for export');
        return null;
      }

      // Step 2: Merge all files into a single PDF
      final outputPath = await _getOutputPath(playlist.name);

      // generatePDFFromDocuments handles both PDFs and images
      final response = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: filePaths,
        outputPath: outputPath,
      );

      if (response.status == PdfCombinerStatus.success) {
        logger.i('Playlist exported successfully to: ${response.outputPath}');
        return response.outputPath;
      } else {
        logger.e('Failed to merge files: ${response.message}');
        return null;
      }
    } catch (e, stackTrace) {
      logger.e('Error exporting playlist', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Downloads all music sheet files and returns their local paths
  Future<List<String>> _downloadAllFiles(
    List<MusicSheet> musicSheets,
  ) async {
    final filePaths = <String>[];
    final totalSheets = musicSheets.length;

    for (var i = 0; i < totalSheets; i++) {
      final sheet = musicSheets[i];
      try {
        final file = await _cacheManager.getSingleFile(sheet.fileUrl);
        filePaths.add(file.path);
        logger.d('Downloaded file ${i + 1}/$totalSheets: ${sheet.fileName}');
      } catch (e, stackTrace) {
        logger.e('Failed to download file', error: e, stackTrace: stackTrace);
        // Continue with other files even if one fails
      }
    }

    return filePaths;
  }

  /// Generates the output path for the exported PDF
  Future<String> _getOutputPath(String playlistName) async {
    final directory = await getApplicationDocumentsDirectory();
    final sanitizedName = _sanitizeFileName(playlistName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/${sanitizedName}_$timestamp.pdf';
  }

  /// Sanitizes the file name by removing invalid characters
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
  }
}
