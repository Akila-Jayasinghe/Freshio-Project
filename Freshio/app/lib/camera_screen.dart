import 'dart:async'; // StreamSubscription
import 'dart:io'; // File handling
import 'dart:ui'; // ImageFilter
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Network monitoring
import 'main.dart'; // Access the 'cameras' global variable
import 'ml_service.dart';
import 'services/sync_service.dart'; // The Sync Service
import 'widgets/feedback_sheet.dart'; // Feedback widget
import '../utils/toast_utils.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  final MLService _mlService = MLService();

  // Sync Variables
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _mlService.loadModel();

    // Auto-Sync Listener: If internet connects, run the full sync automatically
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Check if any of the results indicate a connection
      bool isConnected = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi,
      );

      // Only sync if we are not already syncing
      if (isConnected && !_isSyncing) {
        _performFullSync(silent: true);
      }
    });
  }

  // The Unified Sync Logic (Upload Data + Check for Updates)
  Future<void> _performFullSync({bool silent = false}) async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    if (!silent && mounted) {
      ToastUtils.showInfo(context, "Syncing data & checking updates...");
    }

    try {
      // Run the Bi-Directional Sync Service
      String resultMessage = await SyncService().runFullSync();

      bool hasChanges =
          resultMessage.contains("Uploaded") ||
          resultMessage.contains("updated");

      if (mounted && (!silent || hasChanges)) {
        ToastUtils.showSuccess(context, resultMessage);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(
          context,
          "Sync failed. Check internet connection.",
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // Manual Trigger Button Logic
  Future<void> _manualSyncTrigger() async {
    // Check current connection status
    var connectivityResult = await Connectivity().checkConnectivity();

    // Check if connected
    bool isConnected = connectivityResult.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi,
    );

    if (!isConnected) {
      if (!mounted) return;
      ToastUtils.showWarning(
        context,
        "No Internet. Connect to WiFi or Data to sync.",
      );
    } else {
      // Online? Run the sync visibly.
      _performFullSync(silent: false);
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    // Use high res for a clear preview
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    // Stop listening to internet changes
    _connectivitySubscription?.cancel();
    // Dispose ML Service
    _mlService.dispose();
    // Dispose Camera Controller
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_controller!.value.isInitialized) return;

    setState(() => _isLoading = true);

    try {
      XFile imageFile = await _controller!.takePicture();
      String? result = await _mlService.inspectFruit(imageFile);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result != null) {
        File fileImage = File(imageFile.path);
        _showResultDialog(result, fileImage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  void _showResultDialog(String result, File imageFile) {
    bool isFresh = result.toLowerCase().contains("fresh");
    bool isUnsure =
        result.toLowerCase().contains("unsure") ||
        result.toLowerCase().contains("move closer") ||
        result.toLowerCase().contains("unknown");

    String emoji, titleText;
    Color themeColor;

    if (isUnsure) {
      emoji = "🤔";
      titleText = "Not Sure...";
      themeColor = Colors.grey;
    } else if (isFresh) {
      emoji = "😊";
      titleText = "Yay! It's Fresh!";
      themeColor = Colors.green;
    } else {
      emoji = "😟";
      titleText = "Uh oh! It's Rotten!";
      themeColor = Colors.orangeAccent;
    }

    double confidence = 0.0;
    try {
      final RegExp regex = RegExp(r'(\d+)%');
      final match = regex.firstMatch(result);
      if (match != null) {
        confidence = int.parse(match.group(1)!) / 100.0;
      }
    } catch (e) {
      // Ignore parsing errors
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: themeColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: themeColor.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Scan Another Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text(
                    'Scan Another',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: themeColor.withOpacity(0.4),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Report Issue Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => FeedbackSheet(
                      imageFile: imageFile,
                      aiResult: result,
                      confidence: confidence,
                    ),
                  );
                },
                child: Text(
                  "Wrong prediction? Report it.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    final double scanAreaSize = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Freshio Scanner',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // THE PERMANENT SYNC BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _manualSyncTrigger,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text("Sync"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full Screen Camera Preview
          SizedBox.expand(child: CameraPreview(_controller!)),

          // Dark Overlay with Transparent Center
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanner Corner Borders
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: CustomPaint(
                painter: ScannerCornerPainter(
                  color: Colors.greenAccent,
                  strokeWidth: 5.0,
                ),
              ),
            ),
          ),

          // Instructions Chip
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    color: Colors.black.withOpacity(0.4),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_strong_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Center fruit inside corners",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _isLoading
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.greenAccent,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            "Analyzing... 🍎",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        height: 84,
                        width: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.greenAccent, Colors.green],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for the modern corner borders
class ScannerCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  ScannerCornerPainter({
    required this.color,
    required this.strokeWidth,
    this.cornerLength = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(cornerLength, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
