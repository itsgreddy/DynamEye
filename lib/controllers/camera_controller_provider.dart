import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:dynameye/controllers/tflite_helper.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class CameraControllerProvider extends ChangeNotifier {
  final CameraDescription cameraDescription;
  final ResolutionPreset resolutionPreset;
  CameraController? _controller;
  bool _isProcessing = false;
  bool _isInitializing = false;
  bool _objectDetectionEnabled = false;
  Map<String, dynamic>? _detectionResults;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
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
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // query device zoom range and clamp max to 20×
      final deviceMin = await _controller!.getMinZoomLevel();
      final deviceMax = await _controller!.getMaxZoomLevel();
      _minZoom = deviceMin;
      _maxZoom = math.min(deviceMax, 20.0);

      _currentZoom = _minZoom;
      await _controller!.setZoomLevel(_currentZoom);

      _isInitializing = false;
      notifyListeners();

      // Start image stream if object detection is enabled
      if (_objectDetectionEnabled) {
        await _controller!.startImageStream(_processImage);
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _isInitializing = false;
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

  void enableObjectDetection() {
    if (!_objectDetectionEnabled &&
        _controller != null &&
        _controller!.value.isInitialized) {
      _objectDetectionEnabled = true;
      _controller!.startImageStream(_processImage);
    }
  }

  void disableObjectDetection() {
    if (_objectDetectionEnabled &&
        _controller != null &&
        _controller!.value.isInitialized) {
      _objectDetectionEnabled = false;
      _controller!.stopImageStream();
      _detectionResults = null;
      notifyListeners();
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !_objectDetectionEnabled) return;
    _isProcessing = true;

    try {
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

  Future<List<List<List<List<double>>>>> _preprocessCameraImage(
    CameraImage image,
  ) async {
    final img.Image rgbImage = _convertYUV420toImage(image);
    final img.Image resizedImage = img.copyResize(
      rgbImage,
      width: 300,
      height: 300,
    );

    List<List<List<List<double>>>> input = List.generate(
      1,
      (_) => List.generate(
        300,
        (_) => List.generate(300, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < 300; y++) {
      for (int x = 0; x < 300; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // Normalize to 0-1 range
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    return input;
  }

  img.Image _convertYUV420toImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width: width, height: height);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yRowStride = yPlane.bytesPerRow;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;

    final yPixelStride = 1;
    final uPixelStride = uPlane.bytesPerPixel!;
    final vPixelStride = vPlane.bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x * yPixelStride;
        // Need to adjust u and v indices based on downsampling
        // YUV420 has half resolution for U and V planes
        final int uvX = (x / 2).floor();
        final int uvY = (y / 2).floor();
        final int uIndex = uvY * uRowStride + uvX * uPixelStride;
        final int vIndex = uvY * vRowStride + uvX * vPixelStride;

        // Make sure we don't read outside the buffer
        if (yIndex >= yPlane.bytes.length ||
            uIndex >= uPlane.bytes.length ||
            vIndex >= vPlane.bytes.length)
          continue;

        int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uIndex];
        final int vValue = vPlane.bytes[vIndex];

        // YUV to RGB conversion
        // R = Y + 1.402 * (V - 128)
        // G = Y - 0.344136 * (U - 128) - 0.714136 * (V - 128)
        // B = Y + 1.772 * (U - 128)
        int r = yValue + (1.402 * (vValue - 128)).toInt();
        int g =
            yValue -
            (0.344136 * (uValue - 128)).toInt() -
            (0.714136 * (vValue - 128)).toInt();
        int b = yValue + (1.772 * (uValue - 128)).toInt();

        // Clamp values to 0-255
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgbImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return rgbImage;
  }

  void toggleFlash() async {
    if (_controller == null) return;

    try {
      if (_controller!.value.flashMode == FlashMode.off) {
        await _controller!.setFlashMode(FlashMode.torch);
      } else {
        await _controller!.setFlashMode(FlashMode.off);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  @override
  void dispose() {
    disableObjectDetection();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
