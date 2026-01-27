import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Firebase Core
import 'camera_screen.dart';

// Global variable to hold available cameras
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Ensure that widget binding is initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp();
    print("🔥 Firebase Initialized Successfully!");
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
  }

  // Get the list of available cameras on the device
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error fetching cameras: $e');
  }

  // Run the App
  runApp(const FreshioApp());
}

class FreshioApp extends StatelessWidget {
  const FreshioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freshio',
      debugShowCheckedModeBanner: false, // Hides debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const CameraScreen(), // Set CameraScreen as the start page
    );
  }
}
