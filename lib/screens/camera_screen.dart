import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/camera_controller_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/camera_controls.dart';
import '../services/web_socket_service.dart';
import '../config.dart';
import '../controllers/tflite_helper.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/threshold_control.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late CameraControllerProvider _cameraProvider;
  late WebSocketService _webSocketService;
  double zoom = 2.0;
  double bubbleDiameter = 200.0;
  bool isZoomEnabled = true;
  bool isStreaming = false;
  bool isDetectionEnabled = false;
  bool isThresholdVisible = false;
  int detectionCount = 0;
  DateTime? lastUpdateTime;
  double _baseZoom = 1.0; // for pinch gesture
  Map<String, dynamic>? _detectionResults;

  final String serverUrl = Config.serverUrl;
  final String viewerUrl = Config.viewerUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize TFLite Helper
    TFLiteHelper.loadModel();

    _cameraProvider = CameraControllerProvider(
      cameraDescription: widget.cameras[0],
      resolutionPreset: ResolutionPreset.high,
    )..addListener(_onCameraProviderChanged);

    _cameraProvider.initialize();
    _webSocketService = WebSocketService(serverUrl: serverUrl);
  }

  void _onCameraProviderChanged() {
    if (!mounted) return;

    // Update zoom level
    if (_cameraProvider.isInitialized && _cameraProvider.zoomLevel != zoom) {
      setState(() {
        zoom = _cameraProvider.zoomLevel;
      });
    }

    // Track detection updates for performance monitoring
    if (_cameraProvider.detectionResults != null) {
      final now = DateTime.now();
      final detections =
          _cameraProvider.detectionResults!['detections'] as List<dynamic>;

      setState(() {
        detectionCount = detections.length;
        lastUpdateTime = now;
      });
    }

    // Track detection updates for performance monitoring
    if (_cameraProvider.detectionResults != null) {
      final now = DateTime.now();
      final detections =
          _cameraProvider.detectionResults!['detections'] as List<dynamic>;

      setState(() {
        detectionCount = detections.length;
        lastUpdateTime = now;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive) {
      _stopStreaming();
      _webSocketService.disconnect();

      // Disable detection when app is inactive
      if (isDetectionEnabled) {
        setState(() {
          isDetectionEnabled = false;
          _cameraProvider.disableObjectDetection();
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_webSocketService.isConnected.value) {
        _webSocketService.connect();
      }
    }
  }

  @override
  void dispose() {
    _cameraProvider.removeListener(_onCameraProviderChanged);
    WidgetsBinding.instance.removeObserver(this);

    if (_cameraProvider.isInitialized) {
      _webSocketService.stopStreaming(_cameraProvider.controller!);
    }

    _webSocketService.dispose();
    _cameraProvider.dispose();
    TFLiteHelper.dispose();
    super.dispose();
  }

  void _toggleStreaming() {
    if (isStreaming) {
      _stopStreaming();
    } else {
      _startStreaming();
    }
  }

  void _startStreaming() {
    if (!_webSocketService.isConnected.value) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not connected to server')));
      return;
    }

    if (_cameraProvider.isInitialized) {
      _webSocketService.startStreaming(
        _cameraProvider.controller!,
        zoom: zoom,
        bubbleDiameter: bubbleDiameter,
        isZoomEnabled: isZoomEnabled,
      );
      setState(() {
        isStreaming = true;
      });
    }
  }

  void _stopStreaming() {
    if (_cameraProvider.isInitialized) {
      _webSocketService.stopStreaming(_cameraProvider.controller!);
    }
    if (mounted) {
      setState(() {
        isStreaming = false;
      });
    }
  }

  void _toggleDetection() {
    print(
      'Toggle detection button pressed. Current state: $isDetectionEnabled',
    );

    try {
      setState(() {
        isDetectionEnabled = !isDetectionEnabled;

        if (isDetectionEnabled) {
          print('Enabling object detection');
          _cameraProvider.enableObjectDetection();

          // Reset detection metrics
          detectionCount = 0;
          lastUpdateTime = DateTime.now();

          // Show threshold control when detection is enabled
          isThresholdVisible = true;
        } else {
          print('Disabling object detection');
          _cameraProvider.disableObjectDetection();

          // Hide threshold control when detection is disabled
          isThresholdVisible = false;
        }
      });
    } catch (e, stackTrace) {
      print('Error toggling detection: $e');
      print('Stack trace: $stackTrace');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error toggling detection: $e')));

      setState(() {
        isDetectionEnabled = false;
        isThresholdVisible = false;
      });
    }
  }

  void _toggleThresholdControl() {
    setState(() {
      isThresholdVisible = !isThresholdVisible;
    });
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan to View Stream',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: viewerUrl,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(viewerUrl, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                const Text(
                  'Scan this QR code or use the URL to view the stream',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate time since last update for feedback
    String updateStatus = 'No updates yet';
    if (lastUpdateTime != null) {
      final now = DateTime.now();
      final diff = now.difference(lastUpdateTime!).inMilliseconds;
      updateStatus = 'Last update: ${diff}ms ago';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DynamEye'),
        centerTitle: true,
        actions: [
          // Object Detection toggle
          IconButton(
            icon: Icon(
              isDetectionEnabled ? Icons.visibility : Icons.visibility_off,
              color: isDetectionEnabled ? Colors.green : Colors.grey,
            ),
            onPressed: _toggleDetection,
            tooltip:
                isDetectionEnabled ? 'Disable Detection' : 'Enable Detection',
          ),
          // Threshold settings
          if (isDetectionEnabled)
            IconButton(
              icon: Icon(
                Icons.tune,
                color: isThresholdVisible ? Colors.amber : Colors.grey,
              ),
              onPressed: _toggleThresholdControl,
              tooltip: 'Adjust Detection Threshold',
            ),
          // Detection status indicator
          if (isDetectionEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Objects: $detectionCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Optional debugging info bar
          if (isDetectionEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: Colors.black,
              width: double.infinity,
              child: Text(
                updateStatus,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          // Threshold control
          if (isThresholdVisible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ThresholdControl(
                onThresholdChanged: (value) {
                  // Refresh detections if threshold changed
                  if (isDetectionEnabled) {
                    print('Threshold changed to: ${(value * 100).toInt()}%');
                  }
                },
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                // Original Camera View
                GestureDetector(
                  onScaleStart: (_) {
                    _baseZoom = zoom;
                  },
                  onScaleUpdate: (details) {
                    if (_cameraProvider.isInitialized) {
                      final newZoom = (_baseZoom * details.scale).clamp(
                        _cameraProvider.minZoom,
                        _cameraProvider.maxZoom,
                      );
                      _cameraProvider.setZoomLevel(newZoom);
                      setState(() => zoom = newZoom);
                      if (isStreaming) {
                        _stopStreaming();
                        _startStreaming();
                      }
                    }
                  },
                  child: CameraView(
                    cameraProvider: _cameraProvider,
                    isZoomEnabled: isZoomEnabled,
                    zoom: zoom,
                    bubbleDiameter: bubbleDiameter,
                  ),
                ),

                // Object Detection Overlay with AnimatedBuilder
                if (isDetectionEnabled && _cameraProvider.isInitialized)
                  AnimatedBuilder(
                    animation: _cameraProvider,
                    builder: (context, child) {
                      final results = _cameraProvider.detectionResults;
                      final previewSize =
                          _cameraProvider.controller?.value.previewSize;

                      if (results == null || previewSize == null) {
                        return const SizedBox.shrink();
                      }

                      return DetectionOverlay(
                        results: results,
                        imageSize: Size(previewSize.height, previewSize.width),
                      );
                    },
                  ),
              ],
            ),
          ),
          CameraControls(
            zoom: zoom,
            minZoom: _cameraProvider.minZoom,
            maxZoom: _cameraProvider.maxZoom,
            bubbleDiameter: bubbleDiameter,
            isZoomEnabled: isZoomEnabled,
            onZoomChanged: (value) async {
              await _cameraProvider.setZoomLevel(value);
              setState(() => zoom = value);
              if (isStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
            onBubbleSizeChanged: (value) {
              setState(() => bubbleDiameter = value);
              if (isStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
            onZoomEnabledChanged: (value) {
              setState(() => isZoomEnabled = value);
              if (isStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
          ),
        ],
      ),
    );
  }
}
