import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controller_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/camera_controls.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraControllerProvider _cameraProvider;
  double zoom = 2.0;
  double bubbleDiameter = 200.0;
  bool isZoomEnabled = true;

  @override
  void initState() {
    super.initState();
    _cameraProvider = CameraControllerProvider(
      cameraDescription: widget.cameras[0],
      resolutionPreset: ResolutionPreset.high,
    );
    _cameraProvider.initialize();
  }

  @override
  void dispose() {
    _cameraProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DynamEye'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: CameraView(
              cameraProvider: _cameraProvider,
              isZoomEnabled: isZoomEnabled,
              zoom: zoom,
              bubbleDiameter: bubbleDiameter,
            ),
          ),
          CameraControls(
            zoom: zoom,
            bubbleDiameter: bubbleDiameter,
            isZoomEnabled: isZoomEnabled,
            onZoomChanged: (value) => setState(() => zoom = value),
            onBubbleSizeChanged:
                (value) => setState(() => bubbleDiameter = value),
            onZoomEnabledChanged:
                (value) => setState(() => isZoomEnabled = value),
          ),
        ],
      ),
    );
  }
}
