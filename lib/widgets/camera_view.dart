import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller_provider.dart';
import 'zoom_overlay.dart';

class CameraView extends StatelessWidget {
  final CameraControllerProvider cameraProvider;
  final bool isZoomEnabled;
  final double zoom;
  final double bubbleDiameter;

  const CameraView({
    super.key,
    required this.cameraProvider,
    this.isZoomEnabled = true,
    this.zoom = 2.0,
    this.bubbleDiameter = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraProvider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        ZoomOverlay(
          isZoomEnabled: isZoomEnabled,
          zoom: zoom,
          bubbleDiameter: bubbleDiameter,
          child: CameraPreview(cameraProvider.controller!),
        ),
      ],
    );
  }
}
