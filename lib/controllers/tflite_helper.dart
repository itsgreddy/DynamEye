import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class TFLiteHelper {
  static Interpreter? _interpreter;
  static bool _isModelLoaded = false;
  static List<String> _labels = [];

  // Default confidence threshold
  static double _confidenceThreshold = 0.5;

  // Getter and setter for confidence threshold
  static double get confidenceThreshold => _confidenceThreshold;
  static set confidenceThreshold(double value) {
    // Ensure threshold is between 0 and 1
    _confidenceThreshold = value.clamp(0.0, 1.0);
    print('Detection confidence threshold set to: $_confidenceThreshold');
  }

  static Future<void> loadModel() async {
    try {
      // Load model from assets
      _interpreter = await Interpreter.fromAsset(
        'assets/models/ssd_mobilenet.tflite',
      );
      _isModelLoaded = true;
      print('TFLite model loaded successfully');

      // Log input and output tensor details for debugging
      if (_interpreter != null) {
        final inputTensor = _interpreter!.getInputTensor(0);
        final inputShape = inputTensor.shape;
        final inputType = inputTensor.type;
        print('Model input shape: $inputShape');
        print('Model input type: $inputType');

        final outputTensors = _interpreter!.getOutputTensors();
        for (int i = 0; i < outputTensors.length; i++) {
          print('Output tensor $i shape: ${outputTensors[i].shape}');
          print('Output tensor $i type: ${outputTensors[i].type}');
        }
      }

      await loadLabels();
    } catch (e, stackTrace) {
      print('Error loading model: $e');
      print('Stack trace: $stackTrace');
      _isModelLoaded = false;
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
      print('Loaded ${_labels.length} labels');
    } catch (e) {
      print('Error loading labels: $e');
      // Initialize with some default labels for testing
      _labels = [
        'Background',
        'Person',
        'Car',
        'Chair',
        'Bottle',
        'Laptop',
        'Phone',
        'Book',
      ];
      print('Using default labels instead');
    }
  }

  static Future<Map<String, dynamic>> runModelOnFrame(
    List<List<List<List<int>>>> input,
  ) async {
    if (!_isModelLoaded || _interpreter == null) {
      try {
        await loadModel();
      } catch (e) {
        print('Failed to load model: $e');
        return {'detections': []};
      }
    }

    try {
      print(
        'Running inference on uint8 input tensor of shape: ${input.length}x${input[0].length}x${input[0][0].length}x${input[0][0][0].length}',
      );

      // Create arrays to hold the outputs with explicit types
      var outputLocations = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
      var outputClasses = List.filled(1 * 10, 0).reshape([1, 10]);
      var outputScores = List.filled(1 * 10, 0.0).reshape([1, 10]);
      var numDetections = List.filled(1, 0).reshape([1]);

      // Define outputs map
      Map<int, Object> outputs = {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      };

      // Run inference
      print('Running model inference...');
      _interpreter!.runForMultipleInputs([input], outputs);

      print('Inference completed, processing results');

      // Process results - carefully handle type conversions
      List<Map<String, dynamic>> detections = [];

      // Safely extract the number of detections
      var numDetectedValue = numDetections[0];
      int numDetected;
      if (numDetectedValue is int) {
        numDetected = numDetectedValue;
      } else if (numDetectedValue is double) {
        numDetected = numDetectedValue.toInt();
      } else {
        print(
          'Unexpected type for numDetections: ${numDetectedValue.runtimeType}',
        );
        numDetected = 0;
      }

      print('Number of detections: $numDetected');

      // Safely process each detection
      for (int i = 0; i < numDetected; i++) {
        // Safely extract and convert score
        var scoreValue = outputScores[0][i];
        double score;
        if (scoreValue is double) {
          score = scoreValue;
        } else if (scoreValue is int) {
          score = scoreValue.toDouble();
        } else {
          print('Unexpected type for score: ${scoreValue.runtimeType}');
          continue;
        }

        // Only process detections that meet or exceed the confidence threshold
        if (score >= _confidenceThreshold) {
          // Safely extract and convert class index
          var classIndexValue = outputClasses[0][i];
          int classIndex;
          if (classIndexValue is int) {
            classIndex = classIndexValue;
          } else if (classIndexValue is double) {
            classIndex = classIndexValue.toInt();
          } else {
            print(
              'Unexpected type for classIndex: ${classIndexValue.runtimeType}',
            );
            continue;
          }

          final label = getLabel(classIndex);

          // Extract normalized bounding box coordinates with type safety
          var yminValue = outputLocations[0][i][0];
          var xminValue = outputLocations[0][i][1];
          var ymaxValue = outputLocations[0][i][2];
          var xmaxValue = outputLocations[0][i][3];

          double ymin, xmin, ymax, xmax;

          // Convert values to double if necessary
          ymin =
              (yminValue is double) ? yminValue : (yminValue as num).toDouble();
          xmin =
              (xminValue is double) ? xminValue : (xminValue as num).toDouble();
          ymax =
              (ymaxValue is double) ? ymaxValue : (ymaxValue as num).toDouble();
          xmax =
              (xmaxValue is double) ? xmaxValue : (xmaxValue as num).toDouble();

          // Clamp values to valid range
          ymin = ymin.clamp(0.0, 1.0);
          xmin = xmin.clamp(0.0, 1.0);
          ymax = ymax.clamp(0.0, 1.0);
          xmax = xmax.clamp(0.0, 1.0);

          print(
            'Detection $i: $label (${score.toStringAsFixed(2)}) at [$xmin,$ymin,$xmax,$ymax]',
          );

          detections.add({
            'confidence': score,
            'classIndex': classIndex,
            'label': label,
            'rect': {'x': xmin, 'y': ymin, 'w': xmax - xmin, 'h': ymax - ymin},
          });
        } else {
          print(
            'Detection $i filtered out: score $score < threshold $_confidenceThreshold',
          );
        }
      }

      return {'detections': detections};
    } catch (e, stackTrace) {
      print('Error running model: $e');
      print('Stack trace: $stackTrace');

      // If there's an error, try to analyze what went wrong
      if (_interpreter != null) {
        try {
          final inputTensor = _interpreter!.getInputTensor(0);
          print('Expected input shape: ${inputTensor.shape}');
          print('Expected input type: ${inputTensor.type}');
        } catch (e2) {
          print('Error getting tensor info: $e2');
        }
      }

      // Return empty results on error
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
