import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteHelper {
  static late Interpreter _interpreter;
  static bool _isModelLoaded = false;

  static Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/ssd_mobilenet_v2.tflite',
      );
      _isModelLoaded = true;
    } catch (e) {
      _isModelLoaded = false;
      rethrow;
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
        "confidence": maxScore / 255.0,
        "scores": outputScores,
      };
    } catch (e) {
      rethrow;
    }
  }

  static void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
    }
  }
}
