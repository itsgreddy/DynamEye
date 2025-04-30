import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'tflite_helper.dart';

class CameraControllerProvider with ChangeNotifier {
  final CameraDescription cameraDescription;
  final ResolutionPreset resolutionPreset;
  CameraController? _controller;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  Map<String, dynamic>? _detectionResults;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  Map<String, dynamic>? get detectionResults => _detectionResults;
  bool get isProcessing => _isProcessing;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  double get zoomLevel => _currentZoom;

  CameraControllerProvider({
    required this.cameraDescription,
    this.resolutionPreset = ResolutionPreset.high,
  });

  Future<void> initialize() async {
    if (_controller != null) return;
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _controller = CameraController(
        cameraDescription,
        resolutionPreset,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;

      // query device zoom range and clamp max to 20×
      final deviceMin = await _controller!.getMinZoomLevel();
      final deviceMax = await _controller!.getMaxZoomLevel();
      _minZoom = deviceMin;
      _maxZoom = math.min(deviceMax, 20.0);

      _currentZoom = _minZoom;
      await _controller!.setZoomLevel(_currentZoom);

      notifyListeners();

      await _controller!.startImageStream(_processImage);
    } catch (e) {
      _isInitialized = false;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null) return;
    _currentZoom = zoom.clamp(_minZoom, _maxZoom);
    await _controller!.setZoomLevel(_currentZoom);
    notifyListeners();
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputTensor = await _preprocessCameraImage(image);
      final results = await TFLiteHelper.runModelOnFrame(inputTensor);
      _detectionResults = results;
      notifyListeners();
    } catch (e) {
      // Error handling without debug prints
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessCameraImage(
    CameraImage image,
  ) async {
    final img.Image rgbImage = _convertYUV420toImage(image);
    final img.Image resizedImage = img.copyResize(
      rgbImage,
      width: 224,
      height: 224,
    );

    List<List<List<List<double>>>> input = List.generate(
      1,
      (_) => List.generate(
        224,
        (_) => List.generate(224, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = pixel.r.toDouble(); // Red
        input[0][y][x][1] = pixel.g.toDouble(); // Green
        input[0][y][x][2] = pixel.b.toDouble(); // Blue
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
        if (pixelIndex >= yPlane.bytes.length) continue;
        final int yValue = yPlane.bytes[pixelIndex];
        rgbImage.setPixelRgba(x, y, yValue, yValue, yValue, 255);
      }
    }

    return rgbImage;
  }

  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    TFLiteHelper.dispose();
    notifyListeners();
  }
}
