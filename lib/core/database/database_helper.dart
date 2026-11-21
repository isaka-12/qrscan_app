
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
      version: 2,
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v2: QR codes made with the QR maker ("My codes").
    if (oldVersion < 2) {
      await _createCreatedCodesTable(db);
    }
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
