import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';

abstract class QrScanRepository {
  Future<void> saveScan(Scan scan);
  Future<List<Scan>> getAllScans();
  Future<List<Scan>> searchScans(String query);
  Future<void> clearAllScans();
  Future<List<Scan>> getRecentScans(int limit);
}
