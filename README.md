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
