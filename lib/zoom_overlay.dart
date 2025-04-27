import 'package:flutter/material.dart';

class ZoomOverlay extends StatelessWidget {
  final bool isZoomEnabled;
  final Widget child;

  const ZoomOverlay({
    super.key,
    required this.isZoomEnabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isZoomEnabled) {
      return child;
    }

    return Stack(
      children: [
        child,
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha((0.5 * 255).toInt()),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Transform.scale(
                scale: 2.0,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 