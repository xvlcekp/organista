import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
                  future: imageList[currentIndex.value].getData(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                      case ConnectionState.active:
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      case ConnectionState.done:
                        if (snapshot.hasData) {
                          final data = snapshot.data!;
                          return Image.memory(
                            data,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          );
                        } else {
                          return const Center(
                            child: Text("Failed to load image"),
                          );
                        }
                    }
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

enum SwitchImageSide { left, right }

class SwitchImage extends StatelessWidget {
  final IconData icon;
  final VoidCallback switchImage;
  final SwitchImageSide side;

  const SwitchImage({super.key, required this.icon, required this.switchImage, required this.side});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: side == SwitchImageSide.left ? 16 : null,
      right: side == SwitchImageSide.right ? 16 : null,
      top: MediaQuery.of(context).size.height / 2 - 24,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 48),
        onPressed: switchImage,
      ),
    );
  }
}
