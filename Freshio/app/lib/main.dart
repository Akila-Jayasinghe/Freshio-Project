import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'camera_screen.dart';

// Global variable to hold available cameras
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Ensure that widget binding is initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("🔥 Firebase Initialized Successfully!");
  } catch (e) {
    debugPrint("❌ Firebase Initialization Failed: $e");
  }

  // Get the list of available cameras on the device
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error fetching cameras: $e');
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const CameraScreen(),
    );
  }
}
