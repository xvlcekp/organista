import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FullScreenImageGallery extends HookWidget {
  final List<Reference> imageList;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.imageList,
    this.initialIndex = 0,
  });

  void _handleDoubleTap(TransformationController controller) {
    // Reset the transformation to the original size
    controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    // Use hooks for state management
    final currentIndex = useState(initialIndex);
    final TransformationController controller = useTransformationController(
      initialValue: Matrix4.identity(),
    );

    void goToNextImage() {
      if (currentIndex.value < imageList.length - 1) {
        currentIndex.value++;
      }
    }

    void goToPreviousImage() {
      if (currentIndex.value > 0) {
        currentIndex.value--;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTap: () => _handleDoubleTap(controller),
            child: InteractiveViewer(
              transformationController: controller,
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: FutureBuilder<String>(
                  future: imageList[currentIndex.value].getDownloadURL(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Icon(Icons.broken_image, color: Colors.white);
                    }
                    return Image.network(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          ),
          if (currentIndex.value > 0)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 48),
                onPressed: goToPreviousImage,
              ),
            ),
          // Right Arrow
          if (currentIndex.value < imageList.length - 1)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 48),
                onPressed: goToNextImage,
              ),
            ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
