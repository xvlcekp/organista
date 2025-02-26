import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:pdfx/pdfx.dart';

enum PdfViewMode { full, thumbnail, preview }

class PdfViewerWidget extends HookWidget {
  final String fileUrl;
  final PdfViewMode mode;

  const PdfViewerWidget({
    super.key,
    required this.fileUrl,
    this.mode = PdfViewMode.full, // Default to full mode
  });

  Future<File?> _downloadAndCachePdf(String url) async {
    try {
      return await DefaultCacheManager().getSingleFile(url);
    } catch (e) {
      CustomLogger.instance.e("Failed to load PDF: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfController = useState<PdfController?>(null);
    final isLoading = useState(true);

    useEffect(() {
      Future(() async {
        Future<PdfDocument>? document;

        if (kIsWeb) {
          final response = await get(Uri.parse(fileUrl));
          document = PdfDocument.openData(response.bodyBytes);
        } else {
          final pdfFile = await _downloadAndCachePdf(fileUrl);
          document = pdfFile != null ? PdfDocument.openFile(pdfFile.path) : null;
        }

        pdfController.value = document != null ? PdfController(document: document) : null;
        isLoading.value = false;
      });

      return null;
    }, [fileUrl]);

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pdfController.value == null) {
      return const Center(child: Icon(Icons.error));
    }

    return switch (mode) {
      PdfViewMode.full => getPdfFullView(pdfController),
      PdfViewMode.thumbnail => getPdfThumbnailView(pdfController),
      PdfViewMode.preview => getPdfPreview(pdfController),
    };
  }

  PdfView getPdfPreview(ValueNotifier<PdfController?> pdfController) {
    return PdfView(
      controller: pdfController.value!,
      renderer: (PdfPage page) => page.render(
        width: page.width * 0.5,
        height: page.height * 0.5,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#FFFFFF',
      ),
    );
  }

  PdfView getPdfThumbnailView(ValueNotifier<PdfController?> pdfController) {
    return PdfView(
      controller: pdfController.value!,
      renderer: (PdfPage page) => page.render(
        width: page.width * 0.25,
        height: page.height * 0.25,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#FFFFFF',
      ),
    );
  }

  Stack getPdfFullView(ValueNotifier<PdfController?> pdfController) {
    return Stack(
      children: [
        /// PDF Viewer as the base layer
        Positioned.fill(
          child: PdfView(
            controller: pdfController.value!,
            scrollDirection: Axis.vertical,
          ),
        ),

        /// Page number overlay at the bottom-right
        Positioned(
          bottom: 16, // Adjust to your preference
          right: 16, // Adjust to your preference
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6), // Semi-transparent background
              borderRadius: BorderRadius.circular(8),
            ),
            child: PdfPageNumber(
              controller: pdfController.value!,
              builder: (_, state, loadingState, pagesCount) => DefaultTextStyle(
                style: const TextStyle(fontSize: 18, color: Colors.white),
                child: Text('${pdfController.value!.page}/${pagesCount ?? 0}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
