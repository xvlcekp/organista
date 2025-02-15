import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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

  Future<File> _downloadAndCachePdf(String url) async {
    return await DefaultCacheManager().getSingleFile(url);
  }

  @override
  Widget build(BuildContext context) {
    final pdfController = useState<PdfController?>(null);
    final isLoading = useState(true);

    useEffect(() {
      Future(() async {
        final pdfFile = await _downloadAndCachePdf(fileUrl);
        final document = PdfDocument.openFile(pdfFile.path);
        pdfController.value = PdfController(document: document);
        isLoading.value = false;
      });

      return null; // No cleanup needed
    }, [fileUrl]);

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pdfController.value == null) {
      return const Center(child: Icon(Icons.error));
    }

    switch (mode) {
      case PdfViewMode.full:
        return PdfView(
          controller: pdfController.value!,
          scrollDirection: Axis.vertical,
        );
      case PdfViewMode.thumbnail:
        return PdfView(
          controller: pdfController.value!,
          renderer: (PdfPage page) => page.render(
            width: page.width * 0.25,
            height: page.height * 0.25,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
          ),
        );
      case PdfViewMode.preview:
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
  }
}
