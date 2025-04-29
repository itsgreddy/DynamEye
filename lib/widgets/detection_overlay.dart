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
    final int classIndex = results['class'] as int;
    final double confidence = results['confidence'] as double;

    return Positioned(
      left: 10,
      top: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Class $classIndex\nConfidence: ${(confidence * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
