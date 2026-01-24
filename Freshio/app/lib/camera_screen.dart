import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart'; // access the 'cameras' global variable

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Set up the camera controller
  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    // Select the first camera (Default-back camera)
    _controller = CameraController(cameras[0], ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  // Dispose of the controller when the screen is closed
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Function to capture the image
  Future<void> _captureImage() async {
    if (!_controller!.value.isInitialized) return;

    try {
      // Capture the image and get the file path
      XFile imageFile = await _controller!.takePicture();
      print("Image captured: ${imageFile.path}");

      // TODO: Pass this imageFile to our ML Model!
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Inspect Fruit/Vegetable')),
      body: Stack(
        children: [
          // Display the live camera feed
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // Capture Button at the bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _captureImage,
                backgroundColor: Colors.green,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
