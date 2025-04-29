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

2. **Set up the streaming server:**
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

3. **Run the Flutter app:**
   ```sh
   # For local testing (localhost)
   flutter run --dart-define=SERVER_URL=ws://localhost:8080 --dart-define=VIEWER_URL=http://localhost:8080

   # For testing on a local network (replace with your computer's IP)
   flutter run --dart-define=SERVER_URL=ws://192.168.1.xxx:8080 --dart-define=VIEWER_URL=http://192.168.1.xxx:8080
   ```
   > The app will request camera permission on first launch.

## Server Scripts
The server package includes the following npm scripts:
- `npm start` - Starts the server in production mode
- `npm run dev` - Starts the server in development mode with auto-reload
- `npm test` - (Placeholder for future test implementation)

## File Structure
- `lib/main.dart` — Main app entry point
- `lib/screens/camera_screen.dart` — Camera screen and streaming logic
- `lib/widgets/camera_view.dart` — Camera preview widget
- `lib/widgets/camera_controls.dart` — Camera control widgets
- `lib/services/web_socket_service.dart` — WebSocket streaming service
- `lib/config.dart` — Environment configuration
- `server/` — WebSocket streaming server
  - `src/server.js` — Main server implementation
  - `public/` — Static files for the viewer
  - `package.json` — Server dependencies and scripts

## Configuration
The app uses environment variables for server configuration:
- `SERVER_URL`: WebSocket server URL (default: ws://localhost:8080)
- `VIEWER_URL`: HTTP viewer URL (default: http://localhost:8080)

## Notes
- This is a proof-of-concept, not production code.
- For best results, use on a physical device (not a simulator).
- Make sure your device and computer are on the same network when testing remote viewing.
- The server includes a basic web viewer at the root URL (e.g., http://localhost:8080).

## License
MIT
