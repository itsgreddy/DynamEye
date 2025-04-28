import 'package:camera/camera.dart';

class CameraControllerProvider {
  final CameraDescription cameraDescription;
  final ResolutionPreset resolutionPreset;
  CameraController? _controller;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  CameraControllerProvider({
    required this.cameraDescription,
    this.resolutionPreset = ResolutionPreset.high,
  });

  Future<void> initialize() async {
    _controller = CameraController(
      cameraDescription,
      resolutionPreset,
      enableAudio: false,
    );

    return _controller!.initialize();
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
