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
- WebSocket streaming support for remote viewing

## Prerequisites
- Flutter SDK
- Node.js and npm (for running the streaming server)
- A physical device for testing (not a simulator)

## Getting Started

1. **Install Flutter dependencies:**
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

5. **Set up the streaming server:**
   ```sh
   # Navigate to the server directory
   cd server

   # Install server dependencies
   npm install

   # Start the server in development mode (with auto-reload)
   npm run dev

   # Or start in production mode
   npm start
   ```
   The server will start on port 8080 by default. You can change the port by setting the `PORT` environment variable:
   ```sh
   PORT=3000 npm start
   ```

6. **Run the Flutter app:**
   ```sh
   # For local testing (localhost)
   flutter run --dart-define=SERVER_URL=ws://localhost:8080 --dart-define=VIEWER_URL=http://localhost:8080

   # For testing on a local network (replace with your computer's IP)
   flutter run --dart-define=SERVER_URL=ws://192.168.1.xxx:8080 --dart-define=VIEWER_URL=http://192.168.1.xxx:8080

7. **Clean and Rebuild**:
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

## Server Scripts
The server package includes the following npm scripts:
- `npm start` - Starts the server in production mode
- `npm run dev` - Starts the server in development mode with auto-reload
- `npm test` - (Placeholder for future test implementation)

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
- Make sure your device and computer are on the same network when testing remote viewing.
- The server includes a basic web viewer at the root URL (e.g., http://localhost:8080).

## License
MIT
