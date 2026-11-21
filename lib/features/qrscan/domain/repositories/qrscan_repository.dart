import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';

abstract class QrScanRepository {
  Future<void> saveScan(Scan scan);
  Future<List<Scan>> getAllScans();
  Future<List<Scan>> searchScans(String query);
  Future<void> clearAllScans();

  /// Deletes one scan (matched by its time and content).
  Future<void> deleteScan(Scan scan);
  Future<List<Scan>> getRecentScans(int limit);
}
