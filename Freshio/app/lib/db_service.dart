import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    // Get the path to the local database folder
    String path = join(await getDatabasesPath(), 'freshio_v2.db');
    
    // Open the database (creating it if it doesn't exist)
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create the table with the new columns for Name and Quality
        await db.execute('''
          CREATE TABLE inspections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT,
            ai_result TEXT,
            user_fruit_name TEXT,
            user_quality TEXT,
            confidence REAL,
            timestamp TEXT,
            is_synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // Save a new report when the user corrects the AI
  Future<void> insertInspection({
    required String imagePath,
    required String aiResult,
    required String userFruitName,
    required String userQuality,
    required double confidence,
  }) async {
    final db = await database;
    await db.insert('inspections', {
      'image_path': imagePath,
      'ai_result': aiResult,
      'user_fruit_name': userFruitName,
      'user_quality': userQuality,
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
      'is_synced': 0, // Defaults to 0 (Not yet sent to Firebase)
    });
  }

  // Fetch all unsynced records (for the "Forward" part of Store-and-Forward)
  Future<List<Map<String, dynamic>>> getUnsyncedInspections() async {
    final db = await database;
    return await db.query(
      'inspections',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  // Update status after successful upload to Firebase
  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'inspections',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}