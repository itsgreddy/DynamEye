import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteHelper {
  static late Interpreter _interpreter;

  static Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/ssd_mobilenet_v2.tflite');
  }

  static Future<Map<String, dynamic>> runModelOnFrame(List<List<List<List<double>>>> input) async {
    var outputBoxes = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
    var outputClasses = List.filled(1 * 10, 0.0).reshape([1, 10]);
    var outputScores = List.filled(1 * 10, 0.0).reshape([1, 10]);
    var numDetections = List.filled(1, 0.0);

    Map<int, Object> outputs = {
      0: outputBoxes,
      1: outputClasses,
      2: outputScores,
      3: numDetections,
    };

    _interpreter.runForMultipleInputs([input], outputs);

    return {
      "boxes": outputBoxes,
      "classes": outputClasses,
      "scores": outputScores,
      "num": numDetections,
    };
  }

  static void dispose() {
    _interpreter.close();
  }
}
