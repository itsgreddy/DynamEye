import 'package:flutter/material.dart';

class DetectionOverlay extends StatelessWidget {
  final Map<String, dynamic> results;
  final Size imageSize;

  const DetectionOverlay({
    super.key,
    required this.results,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    // Safety check for empty results
    if (results.isEmpty || !results.containsKey('detections')) {
      return const SizedBox.shrink();
    }

    // Safety check for imageSize
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      print('Invalid image size: $imageSize');
      return const SizedBox.shrink();
    }

    // Safe cast to List<dynamic>
    List<dynamic> detectionsList = [];
    try {
      detectionsList = results['detections'] as List<dynamic>;
    } catch (e) {
      print('Error accessing detections: $e');
      return const SizedBox.shrink();
    }

    // Convert each detection to a widget
    List<Widget> detectionWidgets = [];
    for (final detection in detectionsList) {
      try {
        // Safely access detection data
        if (detection is! Map<String, dynamic>) {
          print('Detection not in expected format: $detection');
          continue;
        }

        // Extract detection properties with type safety
        final confidence = detection['confidence'] as double? ?? 0.0;
        final label = detection['label'] as String? ?? 'Unknown';

        // Extract rect data safely
        final rect = detection['rect'] as Map<String, dynamic>?;
        if (rect == null) {
          print('Detection missing rect data: $detection');
          continue;
        }

        // Extract coordinates with type safety
        final x = (rect['x'] is num) ? (rect['x'] as num).toDouble() : 0.0;
        final y = (rect['y'] is num) ? (rect['y'] as num).toDouble() : 0.0;
        final w = (rect['w'] is num) ? (rect['w'] as num).toDouble() : 0.0;
        final h = (rect['h'] is num) ? (rect['h'] as num).toDouble() : 0.0;

        // Convert normalized coordinates to actual pixels with safety checks
        final pixelX = (x * imageSize.width).clamp(0.0, imageSize.width);
        final pixelY = (y * imageSize.height).clamp(0.0, imageSize.height);
        final pixelW = (w * imageSize.width).clamp(
          0.0,
          imageSize.width - pixelX,
        );
        final pixelH = (h * imageSize.height).clamp(
          0.0,
          imageSize.height - pixelY,
        );

        // Skip if box has invalid dimensions
        if (pixelW <= 0 || pixelH <= 0) {
          print('Invalid box dimensions: $pixelW x $pixelH');
          continue;
        }

        // Add the detection widget to our list
        detectionWidgets.add(
          Positioned(
            left: pixelX,
            top: pixelY,
            child: Container(
              width: pixelW,
              height: pixelH,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.red,
                    child: Text(
                      '$label ${(confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error processing detection: $e');
        // Continue to the next detection instead of failing
        continue;
      }
    }

    return Stack(children: detectionWidgets);
  }
}
