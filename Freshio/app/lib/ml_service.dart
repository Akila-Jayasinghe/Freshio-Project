import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  // _labels
  final List<String> _labels = [
    'Fresh Apple',
    'Fresh Banana',
    'Fresh Orange',
    'Rotten Apple',
    'Rotten Banana',
    'Rotten Orange',
  ];

  Interpreter? _interpreter;

  // Load specific Freshio Model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model/Freshio_model_v02.tflite',
      );
      print('✅ Freshio model loaded successfully!');
    } catch (e) {
      print('❌ Failed to load model: $e');
    }
  }

  // Inject image through the model
  Future<String?> inspectFruit(XFile imageFile) async {
    if (_interpreter == null) return null;

    File file = File(imageFile.path);
    img.Image? originalImage = img.decodeImage(file.readAsBytesSync());
    if (originalImage == null) return null;

    int cropSize = originalImage.width < originalImage.height
        ? originalImage.width
        : originalImage.height;

    int offsetX = (originalImage.width - cropSize) ~/ 2;
    int offsetY = (originalImage.height - cropSize) ~/ 2;

    img.Image croppedImage = img.copyCrop(
      originalImage,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );

    // Resize the cropped square to 224x224 for model req.
    img.Image resizedImage = img.copyResize(
      croppedImage,
      width: 224,
      height: 224,
    );

    var input = _imageToByteList(resizedImage).reshape([1, 224, 224, 3]);

    // List with label count
    var output = List.filled(1 * 6, 0.0).reshape([1, 6]);

    // Run model inference
    _interpreter!.run(input, output);

    // Get results into list
    List<double> probabilities = output[0] as List<double>;

    // Find the highest prob. and its index
    double maxConfidence = 0;
    int maxIndex = 0;
    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        maxIndex = i;
      }
    }

    // If confidence is too low, then tell to try again
    if (maxConfidence < 0.60) {
      return "Not sure! Move closer 🔍";
    }

    // Format the final result string
    String detectedFruit = _labels[maxIndex];
    int confidencePercentage = (maxConfidence * 100).round();

    return "$detectedFruit ($confidencePercentage%)";
  }

  // Helper: Convert image pixels to Float32 array (Normalizes pixels to 0.0 - 1.0)
  Float32List _imageToByteList(img.Image image) {
    var convertedBytes = Float32List(1 * 224 * 224 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < 224; i++) {
      for (var j = 0; j < 224; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r / 255.0).toDouble(); // Red
        buffer[pixelIndex++] = (pixel.g / 255.0).toDouble(); // Green
        buffer[pixelIndex++] = (pixel.b / 255.0).toDouble(); // Blue
      }
    }
    return convertedBytes;
  }

  // Program kill method
  void dispose() {
    _interpreter?.close();
  }
}
