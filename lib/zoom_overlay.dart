import 'package:flutter/material.dart';

class ZoomOverlay extends StatelessWidget {
  final bool isZoomEnabled;
  final Widget child;
  final double zoom;
  final double bubbleDiameter;

  const ZoomOverlay({
    super.key,
    required this.isZoomEnabled,
    required this.child,
    this.zoom = 2.0,
    this.bubbleDiameter = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isZoomEnabled) {
      return child;
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          Container(
            width: bubbleDiameter,
            height: bubbleDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha((0.5 * 255).toInt()),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Transform.scale(
                scaleX: zoom,
                scaleY: zoom * 16 / 9,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
