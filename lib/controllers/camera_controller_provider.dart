import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'tflite_helper.dart';

class CameraControllerProvider with ChangeNotifier {
  final CameraDescription cameraDescription;
  final ResolutionPreset resolutionPreset;
  CameraController? _controller;
  bool _isProcessing = false;
  Map<String, dynamic>? _detectionResults;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  Map<String, dynamic>? get detectionResults => _detectionResults;
  bool get isProcessing => _isProcessing;

  CameraControllerProvider({
    required this.cameraDescription,
    this.resolutionPreset = ResolutionPreset.high,
  });

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    await _controller!.initialize();
    await _controller!.startImageStream(_processImage);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Preprocess the CameraImage into a normalized tensor
      final inputTensor = await _preprocessCameraImage(image);

      final results = await TFLiteHelper.runModelOnFrame(inputTensor);

      _detectionResults = results;
      notifyListeners();
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessCameraImage(CameraImage image) async {
    final img.Image rgbImage = _convertYUV420toImage(image);
    final img.Image resizedImage = img.copyResize(rgbImage, width: 300, height: 300);

    List<List<List<List<double>>>> input = List.generate(1,
      (_) => List.generate(300,
        (_) => List.generate(300,
          (_) => List.filled(3, 0.0))));

    for (int y = 0; y < 300; y++) {
      for (int x = 0; x < 300; x++) {
        final pixel = resizedImage.getPixel(x, y);

        input[0][y][x][0] = (pixel.r - 127.5) / 127.5; // Red
        input[0][y][x][1] = (pixel.g - 127.5) / 127.5; // Green
        input[0][y][x][2] = (pixel.b - 127.5) / 127.5; // Blue
      }
    }
    return input;
  }

  img.Image _convertYUV420toImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width: width, height: height);

    final yPlane = image.planes[0];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = y * yPlane.bytesPerRow + x;
        final int yValue = yPlane.bytes[pixelIndex];

        // Set R=G=B=Y value
        rgbImage.setPixelRgba(x, y, yValue, yValue, yValue, 255);
      }
    }

    return rgbImage;
  }

  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _controller = null;
    TFLiteHelper.dispose();
  }
}
