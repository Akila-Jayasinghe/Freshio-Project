import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart'; // We will create this file next

// Global variable to hold available cameras
List<CameraDescription> cameras = [];

Future<void> main() async {
  // 1. Ensure that widget binding is initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Get the list of available cameras on the device
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error fetching cameras: $e');
  }

  // 3. Run the App
  runApp(const FreshioApp());
}

class FreshioApp extends StatelessWidget {
  const FreshioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freshio',
      debugShowCheckedModeBanner: false, // Hides the debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const CameraScreen(), // Set CameraScreen as the start page
    );
  }
}
