import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FullscreenImageView extends HookWidget {
  final Uint8List imageData;

  const FullscreenImageView({
    super.key,
    required this.imageData,
  });

  void _handleDoubleTap(TransformationController controller) {
    // Reset the transformation to the original size
    controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final TransformationController controller = useTransformationController(
      initialValue: Matrix4.identity(),
    );
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
                child: Image.memory(
                  imageData,
                  fit: BoxFit.contain,
                ),
              ),
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
