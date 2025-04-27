# DynamEye

A Flutter proof-of-concept app that displays a live camera feed with a circular zoom overlay at the center. The zoom region can be toggled on or off, and the app is designed for clean, full-screen visuals (ideal for AR glasses screencasting).

## Features
- Live camera preview using the camera package
- Circular 200x200px zoom region at the center with feathered edge
- Toggle zoom overlay on/off with a floating button
- Clean, minimal UI
- Works on real devices (requires camera permission)

## Getting Started

1. **Install dependencies:**
   ```sh
   flutter pub get
   ```
2. **Run on a real device:**
   ```sh
   flutter run
   ```
   > The app will request camera permission on first launch.

## File Structure
- `lib/main.dart` — Main app logic, camera handling, and UI
- `lib/zoom_overlay.dart` — Zoom overlay widget

## Notes
- This is a proof-of-concept, not production code.
- For best results, use on a physical device (not a simulator).

## License
MIT
