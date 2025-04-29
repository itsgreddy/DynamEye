import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class TFLiteHelper {
  static late Interpreter _interpreter;
  static bool _isModelLoaded = false;
  static List<String> _labels = [];

  static Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/ssd_mobilenet_v2.tflite',
      );
      _isModelLoaded = true;

      await loadLabels();
    } catch (e) {
      _isModelLoaded = false;
      rethrow;
    }
  }

  static Future<void> loadLabels() async {
    try {
      // Load labels from the text file
      final labelsData = await rootBundle.loadString(
        'assets/labels/labels.txt',
      );

      // Split by newline and remove any empty strings
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      print('Loaded ${_labels.length} labels');
    } catch (e) {
      print('Error loading labels: $e');
      // Initialize with an empty list so the app can still run
      _labels = [];
    }
  }

  static Future<Map<String, dynamic>> runModelOnFrame(
    List<List<List<List<int>>>> input,
  ) async {
    if (!_isModelLoaded) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      final outputShape = _interpreter.getOutputTensor(0).shape;
      var outputScores = List.filled(
        outputShape.reduce((a, b) => a * b),
        0,
      ).reshape(outputShape);

      Map<int, Object> outputs = {0: outputScores};

      _interpreter.runForMultipleInputs([input], outputs);

      var scores = outputScores[0] as List<int>;
      var maxScore = 0;
      var maxIndex = 0;
      for (var i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      return {
        "class": maxIndex,
        "label": getLabel(maxIndex),
        "confidence": maxScore / 255.0,
        "scores": outputScores,
      };
    } catch (e) {
      rethrow;
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
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
    }
  }
}
