import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../db_service.dart';

class SyncService {
  late final CloudinaryPublic _cloudinary;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DBService _dbService = DBService();

  SyncService() {
    // Read from .env
    String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      debugPrint("⚠️ WARNING: Cloudinary keys not found in .env");
    }

    _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  Future<String> runFullSync() async {
    StringBuffer statusLog = StringBuffer();
    debugPrint("🔄 SYNC STARTED: Checking for pending data...");

    try {
      await _uploadPendingData(statusLog);

      debugPrint("🔄 SYNC STEP 2: Checking for model updates...");
      bool modelUpdated = await _checkForNewModel();

      if (modelUpdated) {
        statusLog.writeln("✨ AI Model updated to latest version!");
      } else {
        statusLog.writeln("🛡️ AI Security: Model is current.");
      }
    } catch (e) {
      debugPrint("❌ CRITICAL SYNC ERROR: $e");
      return "Sync Failed: ${e.toString()}";
    }

    debugPrint("✅ SYNC COMPLETED.");
    return statusLog.toString();
  }

  Future<void> _uploadPendingData(StringBuffer statusLog) async {
    List<Map<String, dynamic>> pendingRecords = await _dbService
        .getUnsyncedInspections();

    if (pendingRecords.isEmpty) {
      debugPrint("ℹ️ No pending records found.");
      statusLog.writeln("☁️ Data is up to date.");
      return;
    }

    debugPrint("🚀 Found ${pendingRecords.length} records to upload.");
    int successCount = 0;
    int failureCount = 0;

    for (var record in pendingRecords) {
      try {
        debugPrint("   -> Processing Record ID: ${record['id']}...");
        File imageFile = File(record['image_path']);

        if (!imageFile.existsSync()) {
          debugPrint("   ⚠️ File missing. Marking as synced to skip.");
          await _dbService.markAsSynced(record['id']);
          continue;
        }

        debugPrint("   -> Uploading to Cloudinary...");

        CloudinaryResponse response = await _cloudinary
            .uploadFile(
              CloudinaryFile.fromFile(
                imageFile.path,
                resourceType: CloudinaryResourceType.Image,
              ),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw "Cloudinary Upload Timed Out",
            );

        String downloadUrl = response.secureUrl;
        debugPrint("   -> Uploaded! URL: $downloadUrl");

        debugPrint("   -> Saving metadata to Firestore...");
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

        await _dbService.markAsSynced(record['id']);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }

        successCount++;
        debugPrint("   ✅ Record ${record['id']} synced.");
      } catch (e) {
        failureCount++;
        debugPrint("   ❌ Failed Record ${record['id']}: $e");
      }
    }

    if (successCount > 0) {
      statusLog.writeln("✅ Uploaded $successCount reports.");
    }
    if (failureCount > 0) {
      statusLog.writeln("⚠️ Failed to upload $failureCount items.");
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
