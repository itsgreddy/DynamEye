import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'zoom_overlay.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyTestApp());
}

class MyTestApp extends StatelessWidget {
  const MyTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DynamEye Test',
      theme: ThemeData.dark(),
      home: CameraTestScreen(),
    );
  }
}

class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({Key? key}) : super(key: key);

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  CameraController? controller;
  double zoom = 2.0;
  double bubbleDiameter = 200.0;
  bool isZoomEnabled = true;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('DynamEye'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ZoomOverlay(
                  isZoomEnabled: isZoomEnabled,
                  zoom: zoom,
                  bubbleDiameter: bubbleDiameter,
                  child: CameraPreview(controller!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Zoom'),
                    Expanded(
                      child: Slider(
                        value: zoom,
                        min: 1.0,
                        max: 4.0,
                        divisions: 30,
                        label: zoom.toStringAsFixed(2) + 'x',
                        onChanged: (v) => setState(() => zoom = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Bubble Size'),
                    Expanded(
                      child: Slider(
                        value: bubbleDiameter,
                        min: 100.0,
                        max: 300.0,
                        divisions: 20,
                        label: bubbleDiameter.toStringAsFixed(0) + ' px',
                        onChanged: (v) => setState(() => bubbleDiameter = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isZoomEnabled ? 'Zoom ON' : 'Zoom OFF'),
                    Switch(
                      value: isZoomEnabled,
                      onChanged: (v) => setState(() => isZoomEnabled = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
