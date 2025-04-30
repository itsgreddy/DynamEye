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
    if (results.isEmpty || !results.containsKey('detections')) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> detections =
        List<Map<String, dynamic>>.from(results['detections']);

    return Stack(
      children: [
        // Draw bounding boxes for each detection
        ...detections.map((detection) {
          final confidence = detection['confidence'] as double;
          final label = detection['label'] as String;
          final rect = detection['rect'] as Map<String, dynamic>;

          // Convert normalized coordinates to actual pixels
          final x = (rect['x'] as double) * imageSize.width;
          final y = (rect['y'] as double) * imageSize.height;
          final w = (rect['w'] as double) * imageSize.width;
          final h = (rect['h'] as double) * imageSize.height;

          return Positioned(
            left: x,
            top: y,
            child: Container(
              width: w,
              height: h,
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
          );
        }).toList(),
      ],
    );
  }
}
