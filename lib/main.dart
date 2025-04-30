import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';
import 'controllers/tflite_helper.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras
  cameras = await availableCameras();
  
  // Load TFLite model
  await TFLiteHelper.loadModel();
  
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DynamEye',
      theme: ThemeData.dark(),
      home: HomeScreen(cameras: cameras),
    );
  }
}
