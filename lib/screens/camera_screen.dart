import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/camera_controller_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/camera_controls.dart';
import '../services/web_socket_service.dart';
import '../config.dart';

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

  final String serverUrl = Config.serverUrl;
  final String viewerUrl = Config.viewerUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraProvider = CameraControllerProvider(
      cameraDescription: widget.cameras[0],
      resolutionPreset: ResolutionPreset.high,
    )..addListener(_onCameraProviderChanged);

    _cameraProvider.initialize();
    _webSocketService = WebSocketService(serverUrl: serverUrl);
  }

  void _onCameraProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive) {
      // Stop streaming and disconnect when app is inactive
      _stopStreaming();
      _webSocketService.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // Reconnect when app is resumed
      if (_webSocketService.isConnected.value) {
        _webSocketService.connect();
      }
    }
  }

  @override
  void dispose() {
    _cameraProvider.removeListener(_onCameraProviderChanged);
    WidgetsBinding.instance.removeObserver(this);
    _stopStreaming();
    _webSocketService.dispose();
    _cameraProvider.dispose();
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
    setState(() {
      isStreaming = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('DynamEye'),
        centerTitle: true,
        actions: [
          // Connection status indicator and action
          ValueListenableBuilder<bool>(
            valueListenable: _webSocketService.isConnected,
            builder: (context, isConnected, child) {
              return ValueListenableBuilder<String>(
                valueListenable: _webSocketService.connectionStatus,
                builder: (context, status, child) {
                  return Row(
                    children: [
                      // Only show QR code button when connected
                      if (isConnected)
                        IconButton(
                          icon: const Icon(Icons.qr_code),
                          tooltip: 'Show QR Code',
                          onPressed: _showQrCodeDialog,
                        ),
                      // Connection button
                      IconButton(
                        icon: Icon(
                          isConnected ? Icons.link : Icons.link_off,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                        onPressed:
                            isConnected
                                ? _webSocketService.disconnect
                                : _webSocketService.connect,
                        tooltip:
                            isConnected ? 'Disconnect' : 'Connect to server',
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

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
            minZoom: _cameraProvider.minZoom,
            maxZoom: _cameraProvider.maxZoom,
            bubbleDiameter: bubbleDiameter,
            isZoomEnabled: isZoomEnabled,
            onZoomChanged: (value) async {
              await _cameraProvider.setZoomLevel(value);
              setState(() => zoom = value);
              // Update streaming config if active
              if (isStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
            onBubbleSizeChanged: (value) {
              setState(() => bubbleDiameter = value);
              // Update streaming config if active
              if (isStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
            onZoomEnabledChanged: (value) {
              setState(() => isZoomEnabled = value);
              // Update streaming config if active
              if (isStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _webSocketService.isConnected,
        builder: (context, isConnected, child) {
          return FloatingActionButton(
            onPressed: isConnected ? _toggleStreaming : null,
            backgroundColor:
                isConnected
                    ? (isStreaming ? Colors.red : Colors.green)
                    : Colors.grey,
            tooltip: isStreaming ? 'Stop Streaming' : 'Start Streaming',
            child: Icon(isStreaming ? Icons.stop : Icons.cast),
          );
        },
      ),
    );
  }
}
