import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraControllerProvider extends ChangeNotifier {
  final CameraDescription cameraDescription;
  final ResolutionPreset resolutionPreset;
  CameraController? _controller;
  bool _isInitializing = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isInitializing => _isInitializing;

  CameraControllerProvider({
    required this.cameraDescription,
    this.resolutionPreset = ResolutionPreset.high,
  });

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _controller = CameraController(
        cameraDescription,
        resolutionPreset,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing camera: $e');
      _isInitializing = false;
      notifyListeners();
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
