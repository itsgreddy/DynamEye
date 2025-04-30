import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final double bubbleDiameter;
  final bool isZoomEnabled;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onBubbleSizeChanged;
  final ValueChanged<bool> onZoomEnabledChanged;

  const CameraControls({
    super.key,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.bubbleDiameter,
    required this.isZoomEnabled,
    required this.onZoomChanged,
    required this.onBubbleSizeChanged,
    required this.onZoomEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Zoom'),
              Expanded(
                child: Slider(
                  value: zoom,
                  min: minZoom,
                  max: maxZoom,
                  divisions: ((maxZoom - minZoom) * 10).round(),
                  label: '${zoom.toStringAsFixed(2)}x',
                  onChanged: onZoomChanged,
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
                  label: '${bubbleDiameter.toStringAsFixed(0)} px',
                  onChanged: onBubbleSizeChanged,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isZoomEnabled ? 'Zoom ON' : 'Zoom OFF'),
              Switch(value: isZoomEnabled, onChanged: onZoomEnabledChanged),
            ],
          ),
        ],
      ),
    );
  }
}
