import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller_provider.dart';
import 'zoom_overlay.dart';
import 'detection_overlay.dart';

class CameraView extends StatelessWidget {
  final CameraControllerProvider cameraProvider;
  final bool isZoomEnabled;
  final double zoom;
  final double bubbleDiameter;

  const CameraView({
    super.key,
    required this.cameraProvider,
    required this.isZoomEnabled,
    required this.zoom,
    required this.bubbleDiameter,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cameraProvider,
      builder: (context, child) {
        if (!cameraProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            if (!isZoomEnabled) CameraPreview(cameraProvider.controller!),
            if (isZoomEnabled)
              ZoomOverlay(
                isZoomEnabled: isZoomEnabled,
                zoom: zoom,
                bubbleDiameter: bubbleDiameter,
                child: CameraPreview(cameraProvider.controller!),
              ),
            if (cameraProvider.detectionResults != null)
              DetectionOverlay(
                results:
                    cameraProvider
                        .detectionResults!, // Now correctly named and typed
                imageSize: Size(
                  cameraProvider.controller!.value.previewSize!.height,
                  cameraProvider.controller!.value.previewSize!.width,
                ),
              ),
          ],
        );
      },
    );
  }
}
