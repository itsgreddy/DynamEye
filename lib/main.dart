import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'zoom_overlay.dart';
import 'dart:developer';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DynamEye',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: CameraScreen(cameras: cameras),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isZoomEnabled = false;
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Do not initialize camera immediately
  }

  Future<void> _initializeCamera() async {
    log('Requesting camera permission...');
    final status = await Permission.camera.request();
    log('Camera permission status: $status');
    if (status.isGranted) {
      log('Available cameras: ${widget.cameras}');
      if (widget.cameras.isEmpty) {
        log('No cameras found on device.');
        setState(() {
          _errorMessage = 'No cameras found on this device.';
        });
        return;
      }
      log('Initializing camera controller...');
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _controller.initialize();
        log('Camera initialized!');
        setState(() {
          _isCameraInitialized = true;
        });
      } catch (e) {
        log('Error initializing camera: $e');
        setState(() {
          _errorMessage = 'Error initializing camera: $e';
        });
      }
    } else if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
      log('Camera permission not granted.');
      setState(() {
        _errorMessage = 'Camera permission not granted. Please enable it in Settings.';
      });
    }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showCamera) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DynamEye',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _showCamera = true;
                  });
                  await _initializeCamera();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Open Camera'),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showCamera = false;
                _isCameraInitialized = false;
                _errorMessage = null;
              });
            },
          ),
          title: const Text('Camera'),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showCamera = false;
              _isCameraInitialized = false;
              _errorMessage = null;
            });
          },
        ),
        title: const Text('Camera'),
      ),
      body: Stack(
        children: [
          ZoomOverlay(
            isZoomEnabled: _isZoomEnabled,
            child: CameraPreview(_controller),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isZoomEnabled = !_isZoomEnabled;
                });
              },
              child: Icon(
                _isZoomEnabled ? Icons.zoom_out : Icons.zoom_in,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
