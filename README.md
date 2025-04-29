# DynamEye

A Flutter proof-of-concept app designed to demonstrate a dynamic zooming system for assistive navigation.
The app overlays a circular zoom region at the center of a live camera feed, allowing users to selectively magnify parts of their view while keeping the surroundings naturally visible.
It is intended for future integration with AR glasses to aid individuals with visual impairments by enhancing their spatial awareness without disrupting their natural vision.

## Features
- Live camera preview using the camera package
- Centered dynamic zoom bubble with smooth blended edges
- Toggle zoom overlay on/off with a floating button
- Clean, minimal UI
- Optimized for real devices and AR glasses screencasting

## Getting Started

1. **Install dependencies:**
   ```sh
   flutter pub get
   ```

2. **Verify Assets**:
   Ensure the following files exist in the `assets` directory:
   - `assets/models/ssd_mobilenet_v2.tflite`
   - `assets/labels.txt`

   Update the `pubspec.yaml` file to include these assets:
   ```yaml
   flutter:
     assets:
       - assets/models/ssd_mobilenet_v2.tflite
       - assets/labels.txt
   ```

3. **Fix TensorFlow Lite Model Path**:
   Corrected the file path in `TFLiteHelper`:
   ```dart
   _interpreter = await Interpreter.fromAsset('assets/models/ssd_mobilenet_v2.tflite');
   ```

4. **Run CocoaPods**:
   Navigate to the `ios` directory and install pods:
   ```bash
   cd ios
   pod install
   cd ..
   ```

5. **Clean and Rebuild**:
   Clean the project and rebuild it:
   ```bash
   flutter clean
   flutter run
   ```

### Troubleshooting

- **Asset Not Found**:
  Ensure the file paths in `pubspec.yaml` and the code match the actual file locations.

- **CocoaPods Issues**:
  Update CocoaPods and the specs repository:
  ```bash
  sudo gem install cocoapods
  pod repo update
  ```

### Features
- Camera integration for real-time object detection.
- TensorFlow Lite model inference.

### Future Improvements
- Add more models for different use cases.
- Improve UI/UX for better user experience.

## File Structure
- `lib/main.dart` — Main app logic, camera handling, and UI
- `lib/controllers/tflite_helper.dart` — TensorFlow Lite model loading and inference logic
- `lib/controllers/camera_controller_provider.dart` — Camera controller logic
- `lib/screens/camera_screen.dart` — UI for the live camera feed
- `assets/models/ssd_mobilenet_v2.tflite` — TensorFlow Lite model file
- `assets/labels.txt` — Labels for object detection
- `ios/` — iOS-specific configurations and dependencies
- `android/` — Android-specific configurations and dependencies

## Notes
- This is a proof-of-concept, not production code.
- For best results, use on a physical device (not a simulator).

## License
MIT
