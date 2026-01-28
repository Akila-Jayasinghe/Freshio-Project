import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ImageUtils {
  /// Resizes the image to 224x224
  static Future<String> saveOptimizedImage(File rawFile) async {
    final bytes = await rawFile.readAsBytes(); // Read the image

    final rawImage = img.decodeImage(bytes); // Decode image

    if (rawImage == null) throw Exception("Could not decode image");

    final resizedImage = img.copyResize(
      rawImage,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.cubic,
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
