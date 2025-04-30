import 'dart:convert';
import 'dart:typed_data';
import 'package:dynameye/utils/image_converter.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<String> connectionStatus = ValueNotifier('Disconnected');
  bool _isStreaming = false;
  final String serverUrl;

  bool get isStreaming => _isStreaming;

  WebSocketService({this.serverUrl = 'ws://localhost:8080'});

  Future<void> connect() async {
    try {
      connectionStatus.value = 'Connecting...';
      _channel = IOWebSocketChannel.connect(Uri.parse(serverUrl));

      _channel!.stream.listen(
        (message) {
          // Handle incoming messages (e.g., acknowledgements)
          print('Received: $message');
          if (message == 'connected') {
            isConnected.value = true;
            connectionStatus.value = 'Connected';
          }
        },
        onDone: () {
          _handleDisconnection();
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
      );

      // Send initial connection message
      _channel!.sink.add('init');
    } catch (e) {
      print('Failed to connect: $e');
      connectionStatus.value = 'Connection failed: $e';
      isConnected.value = false;
    }
  }

  void _handleDisconnection() {
    isConnected.value = false;
    connectionStatus.value = 'Disconnected';
    _isStreaming = false;
  }

  Future<void> startStreaming(
    CameraController controller, {
    required double zoom,
    required double bubbleDiameter,
    required bool isZoomEnabled,
  }) async {
    if (_isStreaming || !isConnected.value) return;

    _isStreaming = true;
    connectionStatus.value = 'Streaming...';

    // Send stream configuration
    _channel!.sink.add(
      jsonEncode({
        'type': 'config',
        'zoom': zoom,
        'bubbleDiameter': bubbleDiameter,
        'isZoomEnabled': isZoomEnabled,
      }),
    );

    controller.startImageStream((CameraImage image) async {
      if (!_isStreaming || !isConnected.value) {
        stopStreaming(controller);
        return;
      }

      print("Received camera frame: ${image.width}x${image.height}");

      try {
        // Process and send only the zoomed bubble image
        final processedImage = await _processImage(
          image,
          zoom,
          bubbleDiameter,
          isZoomEnabled,
        );

        if (processedImage != null) {
          print("Sending image: ${processedImage.length} bytes");
          _channel!.sink.add(processedImage);
        } else {
          print("Failed to process image - returned null");
        }
      } catch (e) {
        print('Error processing image: $e');
      }
    });
  }

  void stopStreaming(CameraController controller) {
    if (!_isStreaming) return;

    try {
      controller.stopImageStream();
    } catch (e) {
      print('Error stopping stream: $e');
    }

    _isStreaming = false;
    connectionStatus.value = 'Connected';

    if (_channel != null && isConnected.value) {
      _channel!.sink.add(jsonEncode({'type': 'stop'}));
    }
  }

  Future<Uint8List?> _processImage(
    CameraImage image,
    double zoom,
    double bubbleDiameter,
    bool isZoomEnabled,
  ) async {
    try {
      // Step 1: Convert YUV to RGB
      print("Converting YUV to RGB...");
      final fullImage = await ImageConverter.convertYUV420toImage(image);
      if (fullImage == null) {
        print("YUV to RGB conversion failed");
        return null;
      }

      // Step 2: Process based on zoom settings
      print("Processing with zoom=$zoom, bubbleDiameter=$bubbleDiameter");
      if (!isZoomEnabled) {
        // If zoom is disabled, just convert the whole image
        return ImageConverter.encodeJpeg(fullImage);
      }

      // Step 3: Extract the bubble area with zoom
      final zoomedImage = ImageConverter.cropBubbleArea(
        fullImage,
        bubbleDiameter,
        zoom,
      );

      if (zoomedImage == null) {
        print("Cropping bubble area failed");
        return null;
      }

      // Step 4: Convert to JPEG for more efficient transport
      return ImageConverter.encodeJpeg(zoomedImage);
    } catch (e) {
      print('Error in _processImage: $e');
      return null;
    }
  }

  void disconnect() {
    _isStreaming = false;
    _channel?.sink.close();
    isConnected.value = false;
    connectionStatus.value = 'Disconnected';
  }

  void dispose() {
    disconnect();
    isConnected.dispose();
    connectionStatus.dispose();
  }
}
