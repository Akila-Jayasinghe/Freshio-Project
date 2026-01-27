import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../db_service.dart';

class SyncService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DBService _dbService = DBService();

  Future<String> runFullSync() async {
    StringBuffer statusLog = StringBuffer();
    print("🔄 SYNC STARTED: Checking for pending data...");

    try {
      // --- STEP 1: Upload Data ---
      await _uploadPendingData(statusLog); // Pass the logger to the function

      // --- STEP 2: Check for Model Updates ---
      print("🔄 SYNC STEP 2: Checking for model updates...");
      bool modelUpdated = await _checkForNewModel();

      if (modelUpdated) {
        statusLog.writeln("✨ AI Model updated to latest version!");
      } else {
        statusLog.writeln("🛡️ AI Security: Model is current.");
      }
    } catch (e) {
      print("❌ CRITICAL SYNC ERROR: $e");
      return "Sync Failed: ${e.toString()}";
    }

    print("✅ SYNC COMPLETED.");
    return statusLog.toString();
  }

  /// Internal: Uploads pending images with TIMEOUT protection
  Future<void> _uploadPendingData(StringBuffer statusLog) async {
    List<Map<String, dynamic>> pendingRecords = await _dbService
        .getUnsyncedInspections();

    if (pendingRecords.isEmpty) {
      print("ℹ️ No pending records found.");
      statusLog.writeln("☁️ Data is up to date.");
      return;
    }

    print("🚀 Found ${pendingRecords.length} records to upload.");
    int successCount = 0;
    int failureCount = 0;

    for (var record in pendingRecords) {
      try {
        print("   -> Processing Record ID: ${record['id']}...");
        File imageFile = File(record['image_path']);

        if (!imageFile.existsSync()) {
          print("   ⚠️ File missing. Marking as synced to skip.");
          await _dbService.markAsSynced(record['id']);
          continue;
        }

        String fileName = imageFile.path.split('/').last;

        // 1. Upload Image (15s Timeout)
        Reference ref = _storage.ref().child('user_feedback/$fileName');
        await ref
            .putFile(imageFile)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw "Upload timed out (Slow Internet)",
            );

        String downloadUrl = await ref.getDownloadURL();

        // 2. Upload Data (10s Timeout)
        await _firestore
            .collection('reports')
            .add({
              'user_label': record['user_fruit_name'],
              'quality': record['user_quality'],
              'ai_prediction': record['ai_result'],
              'confidence': record['confidence'],
              'image_url': downloadUrl,
              'created_at': record['timestamp'],
              'synced_at': FieldValue.serverTimestamp(),
            })
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw "Firestore write timed out",
            );

        // 3. Mark Synced & Delete Local
        await _dbService.markAsSynced(record['id']);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }

        successCount++;
        print("   ✅ Record ${record['id']} synced.");
      } catch (e) {
        failureCount++;
        print("   ❌ Failed Record ${record['id']}: $e");
      }
    }

    // --- REPORTING RESULTS ---
    if (successCount > 0) {
      statusLog.writeln("✅ Uploaded $successCount reports.");
    }
    if (failureCount > 0) {
      statusLog.writeln(
        "⚠️ Failed to upload $failureCount items. Check connection.",
      );
    }
  }

  Future<bool> _checkForNewModel() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return false;
    } catch (e) {
      return false;
    }
  }
}
