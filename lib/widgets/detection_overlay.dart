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
    final List boxes = results['boxes'][0];
    final List scores = results['scores'][0];
    final List classes = results['classes'][0];

    return Stack(
      children: [
        for (int i = 0; i < boxes.length; i++)
          if (scores[i] > 0.5) // Only show high confidence
            Positioned(
              left: boxes[i][1] * imageSize.width,
              top: boxes[i][0] * imageSize.height,
              width: (boxes[i][3] - boxes[i][1]) * imageSize.width,
              height: (boxes[i][2] - boxes[i][0]) * imageSize.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Text(
                  'Class ${(classes[i]).toInt()}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
      ],
    );
  }
}
