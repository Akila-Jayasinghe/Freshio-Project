import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ImageUtils {
  // Processes the image exactly like the ML model:
  // Center Crops to a square (preserves aspect ratio) -> Resizes to 224x224
  static Future<String> saveOptimizedImage(File rawFile) async {
    final bytes = await rawFile.readAsBytes();
    final rawImage = img.decodeImage(bytes);

    if (rawImage == null) throw Exception("Could not decode image");

    // CENTER CROP
    int cropSize = rawImage.width < rawImage.height
        ? rawImage.width
        : rawImage.height;

    int offsetX = (rawImage.width - cropSize) ~/ 2;
    int offsetY = (rawImage.height - cropSize) ~/ 2;

    final croppedImage = img.copyCrop(
      rawImage,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );

    // resize 224x224
    final resizedImage = img.copyResize(
      croppedImage,
      width: 224,
      height: 224,
      interpolation:
          img.Interpolation.linear, // Linear is faster/standard for ML
    );

    final directory = await getApplicationDocumentsDirectory();

    // Generate a unique filename
    final fileName = 'freshio_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savePath = join(directory.path, fileName);

    // Save as a compressed JPEG
    final optimizedFile = File(savePath);
    await optimizedFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 85));

    return savePath;
  }
}
