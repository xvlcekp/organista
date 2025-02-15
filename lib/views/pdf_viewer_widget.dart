import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerWidget extends HookWidget {
  final String fileUrl;

  const PdfViewerWidget({
    super.key,
    required this.fileUrl,
  });

  Future<File> _downloadAndCachePdf(String url) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    return file;
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
    }, []);

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pdfController.value == null) {
      return const Center(child: Icon(Icons.error));
    }

    return PdfView(
      controller: pdfController.value!,
      scrollDirection: Axis.vertical,
    );
  }
}
