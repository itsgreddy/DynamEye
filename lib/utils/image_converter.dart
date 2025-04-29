import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageConverter {
  /// Converts YUV420 camera image to RGB format
  /// This is a basic implementation - you might need to optimize it for production
  static Future<img.Image?> convertYUV420toImage(CameraImage image) async {
    try {
      if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(image);
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(image);
      }
      print('Unsupported image format: ${image.format.group}');
      return null;
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  static img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image _convertYUV420(CameraImage image) {
    // Existing YUV420 conversion code if needed
    // For now, return null as placeholder
    return img.Image(width: image.width, height: image.height);
  }

  /// Crops an image to extract just the bubble area
  static img.Image? cropBubbleArea(
    img.Image fullImage,
    double bubbleDiameter,
    double zoom,
  ) {
    try {
      final int centerX = fullImage.width ~/ 2;
      final int centerY = fullImage.height ~/ 2;
      final int radius = (bubbleDiameter / 2).round();

      // Calculate the size of the area to crop (smaller because we'll zoom in)
      final int cropWidth = (radius * 2 / zoom).round();
      final int cropHeight = (radius * 2 / zoom).round();

      // Calculate the starting position for the crop
      final int cropStartX = centerX - (cropWidth ~/ 2);
      final int cropStartY = centerY - (cropHeight ~/ 2);

      // Make sure the crop area is within the bounds of the image
      if (cropStartX < 0 ||
          cropStartY < 0 ||
          cropStartX + cropWidth > fullImage.width ||
          cropStartY + cropHeight > fullImage.height) {
        print('Crop area outside image bounds');
        return null;
      }

      // Crop the image
      final croppedImage = img.copyCrop(
        fullImage,
        x: cropStartX,
        y: cropStartY,
        width: cropWidth,
        height: cropHeight,
      );

      // Resize the cropped area to the bubble size (applying zoom)
      return img.copyResize(
        croppedImage,
        width: radius * 2,
        height: radius * 2,
      );
    } catch (e) {
      print('Error cropping bubble area: $e');
      return null;
    }
  }

  /// Converts an image to JPEG format with the specified quality
  static Uint8List? encodeJpeg(img.Image image) {
    return Uint8List.fromList(img.encodeJpg(image, quality: 70));
  }
}
