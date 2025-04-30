import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DynamEye',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'turns your',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CameraScreen(cameras: cameras),
                      ),
                    );
                  },
                  child: const Text('Vision without Limits'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
