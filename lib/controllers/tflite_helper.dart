import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class TFLiteHelper {
  static Interpreter? _interpreter;
  static bool _isModelLoaded = false;
  static List<String> _labels = [];

  static Future<void> loadModel() async {
    try {
      // Load model from assets
      _interpreter = await Interpreter.fromAsset(
        'assets/models/ssd_mobilenet.tflite',
      );
      _isModelLoaded = true;

      await loadLabels();
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  static Future<void> loadLabels() async {
    try {
      // Load labels from the text file
      final labelsData = await rootBundle.loadString(
        'assets/labels/ssd_mobilenet.txt',
      );

      // Split by newline and remove any empty strings
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      print('Error loading labels: $e');
      // Initialize with an empty list so the app can still run
      _labels = [];
    }
  }

  static Future<Map<String, dynamic>> runModelOnFrame(
    List<List<List<List<double>>>> input,
  ) async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
    }

    try {
      // SSD MobileNet typically has these outputs:
      // 1. Locations/bounding boxes
      // 2. Class scores
      // 3. Number of detections

      // Define output tensors with appropriate shapes
      // These shapes match the SSD MobileNet model output
      final outputLocations = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
      final outputClasses = List.filled(1 * 10, 0).reshape([1, 10]);
      final outputScores = List.filled(1 * 10, 0.0).reshape([1, 10]);
      final numDetections = List.filled(1, 0).reshape([1]);

      // Define outputs map
      Map<int, Object> outputs = {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      };

      // Run inference
      _interpreter!.runForMultipleInputs([input], outputs);

      // Process results
      List<Map<String, dynamic>> detections = [];
      int numDetected = (numDetections[0] as int).toInt();

      for (int i = 0; i < numDetected; i++) {
        if ((outputScores[0][i] as double) > 0.5) {
          // Confidence threshold
          final score = outputScores[0][i] as double;
          final classIndex = (outputClasses[0][i] as int).toInt();
          final label = getLabel(classIndex);

          // Extract normalized bounding box (values between 0-1)
          final ymin = (outputLocations[0][i][0] as double).clamp(0.0, 1.0);
          final xmin = (outputLocations[0][i][1] as double).clamp(0.0, 1.0);
          final ymax = (outputLocations[0][i][2] as double).clamp(0.0, 1.0);
          final xmax = (outputLocations[0][i][3] as double).clamp(0.0, 1.0);

          detections.add({
            'confidence': score,
            'classIndex': classIndex,
            'label': label,
            'rect': {'x': xmin, 'y': ymin, 'w': xmax - xmin, 'h': ymax - ymin},
          });
        }
      }

      return {'detections': detections};
    } catch (e) {
      print('Error running model: $e');
      return {'detections': []};
    }
  }

  static String getLabel(int index) {
    if (_labels.isEmpty) {
      return 'Class $index';
    }

    // Make sure index is within bounds
    if (index >= 0 && index < _labels.length) {
      return _labels[index];
    } else {
      return 'Unknown (Class $index)';
    }
  }

  // Get all loaded labels
  static List<String> get labels => _labels;

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
