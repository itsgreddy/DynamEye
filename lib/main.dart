import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/camera_screen.dart';
import 'controllers/tflite_helper.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras
  cameras = await availableCameras();
  
  // Load TFLite model
  await TFLiteHelper.loadModel();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DynamEye',
      theme: ThemeData.dark(),
      home: CameraScreen(cameras: cameras),
    );
  }
}
