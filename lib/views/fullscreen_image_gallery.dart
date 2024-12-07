import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/fragments/switch_image.dart';
import 'package:organista/managers/image_cache_manager.dart';

class FullScreenImageGallery extends HookWidget {
  final List<Reference> imageList;
  final int initialIndex;
  final ImageCacheManager cacheManager;

  const FullScreenImageGallery({
    super.key,
    required this.imageList,
    this.initialIndex = 0,
    required this.cacheManager,
  });

  void _handleDoubleTap(TransformationController controller) {
    // Reset the transformation to the original size
    controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    // Use hooks for state management
    final currentIndex = useState(initialIndex);
    final TransformationController controller = useTransformationController();

    bool notLastImage() => currentIndex.value < imageList.length - 1;
    bool notFirstImage() => currentIndex.value > 0;

    void goToNextImage() {
      if (notLastImage()) {
        currentIndex.value++;
      }
    }

    void goToPreviousImage() {
      if (notFirstImage()) {
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
                child: FutureBuilder<Uint8List?>(
                  future: cacheManager.loadImage(imageList[currentIndex.value]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          ),
          // Left Arrow
          if (notFirstImage())
            SwitchImage(
              switchImage: goToPreviousImage,
              icon: Icons.arrow_back,
              side: SwitchImageSide.left,
            ),
          // Right Arrow
          if (notLastImage())
            SwitchImage(
              switchImage: goToNextImage,
              icon: Icons.arrow_forward,
              side: SwitchImageSide.right,
            ),
          // Close (X) left upper part
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
