// lib/features/qrscan/data/datasources/qrscan_local_datasource.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/scan_model.dart';

class QrScanLocalDataSource {
  final DatabaseHelper _databaseHelper;

  QrScanLocalDataSource(this._databaseHelper);

  /// Insert a new scan into the local database
  Future<int> insertScan(ScanModel scan) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final scanData = {
      'qr_data': scan.qrData,
      'timestamp': scan.timestamp.toIso8601String(),
      'latitude': scan.latitude,
      'longitude': scan.longitude,
      'address': scan.address,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert('scans', scanData);
  }

  /// Retrieve all scans from the local database, ordered by timestamp (newest first)
  Future<List<ScanModel>> getAllScans() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ScanModel.fromMap(map)).toList();
  }

  /// Get scans with pagination support
  Future<List<ScanModel>> getScansWithPagination({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => ScanModel.fromMap(map)).toList();
  }

  /// Search scans by QR data or address
  Future<List<ScanModel>> searchScans(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'qr_data LIKE ? OR address LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ScanModel.fromMap(map)).toList();
  }

  /// Get scan by ID
  Future<ScanModel?> getScanById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ScanModel.fromMap(maps.first);
  }

  /// Update an existing scan
  Future<int> updateScan(int id, ScanModel scan) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final scanData = {
      'qr_data': scan.qrData,
      'timestamp': scan.timestamp.toIso8601String(),
      'latitude': scan.latitude,
      'longitude': scan.longitude,
      'address': scan.address,
      'updated_at': now,
    };

    return await db.update('scans', scanData, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a specific scan
  Future<int> deleteScan(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all scans (clear history)
  Future<int> deleteAllScans() async {
    final db = await _databaseHelper.database;
    return await db.delete('scans');
  }

  /// Get total count of scans
  Future<int> getScansCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM scans');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get scans from a specific date range
  Future<List<ScanModel>> getScansByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ScanModel.fromMap(map)).toList();
  }

  /// Get recent scans (last N scans)
  Future<List<ScanModel>> getRecentScans(int limit) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => ScanModel.fromMap(map)).toList();
  }
}
