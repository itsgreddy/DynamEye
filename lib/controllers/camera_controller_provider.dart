import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../controllers/tflite_helper.dart';
import 'package:flutter/foundation.dart';

class CameraControllerProvider extends ChangeNotifier {
  final CameraDescription cameraDescription;
  final ResolutionPreset resolutionPreset;
  CameraController? _controller;
  bool _isProcessing = false;
  bool _isInitializing = false;
  bool _objectDetectionEnabled = false;
  Map<String, dynamic>? _detectionResults;
  int _frameCount = 0;
  bool _isRealTimeDetectionActive = false;

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
  bool get isRealTimeDetectionActive => _isRealTimeDetectionActive;

  CameraControllerProvider({
    required this.cameraDescription,
    this.resolutionPreset = ResolutionPreset.high,
  });

  Future<void> initialize() async {
    if (_controller != null) return;
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      print('Initializing camera...');

      _controller = CameraController(
        cameraDescription,
        // Use medium resolution for better performance with detection
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      print('Waiting for camera controller to initialize...');
      await _controller!.initialize();

      print('Camera initialized successfully');
      print('Preview size: ${_controller!.value.previewSize}');
      print('Is streaming images: ${_controller!.value.isStreamingImages}');

      // Set zoom levels
      if (_controller!.value.isInitialized) {
        try {
          final deviceMin = await _controller!.getMinZoomLevel();
          final deviceMax = await _controller!.getMaxZoomLevel();
          _minZoom = deviceMin;
          _maxZoom = math.min(deviceMax, 5.0);
          _currentZoom = _minZoom;
          await _controller!.setZoomLevel(_currentZoom);
          print(
            'Zoom levels set: min=$_minZoom, max=$_maxZoom, current=$_currentZoom',
          );
        } catch (e) {
          print('Error setting zoom levels: $e');
          _minZoom = 1.0;
          _maxZoom = 5.0;
          _currentZoom = 1.0;
        }
      }

      _isInitializing = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error initializing camera: $e');
      print('Stack trace: $stackTrace');
      _isInitializing = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
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
      _isRealTimeDetectionActive = true;

      // Start image stream for real-time detection
      if (!_controller!.value.isStreamingImages) {
        print('Starting camera stream for detection');
        _controller!.startImageStream(_processImage);
      }

      notifyListeners();
    }
  }

  void disableObjectDetection() {
    if (_objectDetectionEnabled) {
      _objectDetectionEnabled = false;
      _isRealTimeDetectionActive = false;

      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.value.isStreamingImages) {
        print('Stopping camera stream for detection');
        _controller!.stopImageStream();
      }

      _detectionResults = null;
      notifyListeners();
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !_objectDetectionEnabled) return;
    _isProcessing = true;

    try {
      // Process every 3rd frame for better performance
      _frameCount++;
      if (_frameCount % 3 != 0) {
        _isProcessing = false;
        return;
      }

      print('Processing frame $_frameCount');
      print('Image format: ${image.format.raw}');
      print('Image dimensions: ${image.width}x${image.height}');

      // Convert and preprocess the image
      final inputTensor = await _preprocessCameraImage(image);

      print('Input tensor prepared, running model');

      // Process through TFLite model
      final results = await TFLiteHelper.runModelOnFrame(inputTensor);

      // Update detection results if detection is still active
      if (_isRealTimeDetectionActive) {
        _detectionResults = results;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      print('Error processing image: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<List<List<List<int>>>>> _preprocessCameraImage(
    CameraImage image,
  ) async {
    print('Converting image to RGB');
    final img.Image rgbImage = _convertYUV420toImage(image);

    print('Resizing image to 300x300');
    final img.Image resizedImage = img.copyResize(
      rgbImage,
      width: 300,
      height: 300,
    );

    print('Creating input tensor with shape [1, 300, 300, 3] as uint8');
    // Create a tensor with shape [1, 300, 300, 3] for uint8 (0-255 values)
    List<List<List<List<int>>>> input = List.generate(
      1,
      (_) => List.generate(
        300,
        (_) => List.generate(300, (_) => List.filled(3, 0)),
      ),
    );

    // Fill the tensor with pixel values (without normalization, since we need uint8)
    for (int y = 0; y < 300; y++) {
      for (int x = 0; x < 300; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // Use the full 0-255 range for uint8
        input[0][y][x][0] = pixel.r as int;
        input[0][y][x][1] = pixel.g as int;
        input[0][y][x][2] = pixel.b as int;
      }
    }

    print('Input tensor created with uint8 values');
    return input;
  }

  img.Image _convertYUV420toImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width: width, height: height);

    // Use the most reliable conversion method based on image format
    if (image.format.group == ImageFormatGroup.bgra8888) {
      // For BGRA format (most compatible)
      final plane = image.planes[0];
      final bytes = plane.bytes;
      final stride = plane.bytesPerRow;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixelOffset = y * stride + x * 4;

          // Check we're not going out of bounds
          if (pixelOffset + 2 >= bytes.length) continue;

          // BGRA order
          final b = bytes[pixelOffset];
          final g = bytes[pixelOffset + 1];
          final r = bytes[pixelOffset + 2];

          rgbImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return rgbImage;
    }

    // Fall back to luminance only for other formats
    final yPlane = image.planes[0];
    final yRowStride = yPlane.bytesPerRow;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;

        // Make sure we don't read outside the buffer
        if (yIndex >= yPlane.bytes.length) continue;

        // Get luminance value
        final int lum = yPlane.bytes[yIndex];

        // Set grayscale value for all channels
        rgbImage.setPixelRgba(x, y, lum, lum, lum, 255);
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
    _isRealTimeDetectionActive = false;
    disableObjectDetection();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
