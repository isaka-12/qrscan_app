import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// A helper class for creating local databas using sqflite
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'qr_scans.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        qr_data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index on timestamp for faster queries
    await db.execute('''
      CREATE INDEX idx_scans_timestamp ON scans(timestamp DESC)
    ''');

    await _createCreatedCodesTable(db);
    await _createLibraryTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v2: QR codes made with the QR maker ("My codes").
    if (oldVersion < 2) {
      await _createCreatedCodesTable(db);
    }
    // v3: photo library (folders + photos).
    if (oldVersion < 3) {
      await _createLibraryTables(db);
    }
  }

  Future<void> _createLibraryTables(Database db) async {
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    // file_name is relative to the app's photo directory; folder_id NULL
    // means "not in a folder".
    await db.execute('''
      CREATE TABLE photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_id INTEGER,
        file_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_photos_folder ON photos(folder_id)');
    await db.execute(
      'CREATE INDEX idx_photos_created ON photos(created_at DESC)',
    );
  }

  Future<void> _createCreatedCodesTable(Database db) async {
    await db.execute('''
      CREATE TABLE created_codes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        fields TEXT NOT NULL,
        style TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_created_codes_updated ON created_codes(updated_at DESC)
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'qr_scans.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
