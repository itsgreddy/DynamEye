import 'package:flutter/material.dart';
import '../controllers/tflite_helper.dart';

class ThresholdControl extends StatefulWidget {
  final Function(double)? onThresholdChanged;

  const ThresholdControl({Key? key, this.onThresholdChanged}) : super(key: key);

  @override
  State<ThresholdControl> createState() => _ThresholdControlState();
}

class _ThresholdControlState extends State<ThresholdControl> {
  double _threshold = TFLiteHelper.confidenceThreshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Detection Threshold:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_threshold * 100).toInt()}%',
                style: TextStyle(
                  color: _getConfidenceColor(_threshold),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _threshold,
            min: 0.1,
            max: 0.9,
            divisions: 8,
            activeColor: _getConfidenceColor(_threshold),
            label: '${(_threshold * 100).toInt()}%',
            onChanged: (value) {
              setState(() {
                _threshold = value;
              });
              // Update the global threshold
              TFLiteHelper.confidenceThreshold = value;
              // Call the callback if provided
              if (widget.onThresholdChanged != null) {
                widget.onThresholdChanged!(value);
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Lower (more detections)',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                'Higher (fewer detections)',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get color based on confidence (red for low, yellow for medium, green for high)
  Color _getConfidenceColor(double confidence) {
    if (confidence < 0.4) {
      return Colors.red;
    } else if (confidence < 0.7) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
}
