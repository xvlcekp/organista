import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/services/music_xml_converter/music_xml_to_png_converter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

/// Service for exporting playlist music sheets to a single PDF file
class ExportPlaylistService {
  final CacheManager _cacheManager;
  final MusicXmlToPngConverter _musicXmlConverter;

  /// [musicXmlConverter] is injectable for tests.
  ExportPlaylistService({
    required CacheManager cacheManager,
    MusicXmlToPngConverter? musicXmlConverter,
  }) : _cacheManager = cacheManager,
       _musicXmlConverter = musicXmlConverter ?? MusicXmlToPngConverter();

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

      // The combiner accepts both PDF and image inputs directly
      final resultPath = await PdfCombiner.generatePDFFromDocuments(
        inputs: filePaths.map(MergeInput.path).toList(),
        outputPath: outputPath,
      );

      logger.i('Playlist exported successfully to: $resultPath');
      return resultPath;
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

    for (final (index, sheet) in musicSheets.indexed) {
      try {
        final sheetPaths = await _resolveExportPaths(sheet);
        filePaths.addAll(sheetPaths);
        logger.d(
          'Prepared file ${index + 1}/${musicSheets.length}: ${sheet.fileName} (${sheetPaths.length} page(s))',
        );
      } catch (e, stackTrace) {
        logger.e('Failed to prepare file for export', error: e, stackTrace: stackTrace);
        // Continue with other files even if one fails
      }
    }

    return filePaths;
  }

  /// Resolves a single sheet to the local file paths the combiner should merge.
  /// MusicXML expands to one PNG per rendered page; PDFs and images contribute
  /// the downloaded file itself.
  Future<List<String>> _resolveExportPaths(MusicSheet sheet) async {
    final file = await _cacheManager.getSingleFile(sheet.fileUrl);
    return switch (sheet.mediaType) {
      MediaType.musicxml => await _musicXmlConverter.convertToPngFiles(
        musicSheet: sheet,
        fileBytes: await file.readAsBytes(),
      ),
      MediaType.pdf || MediaType.image => [file.path],
    };
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
