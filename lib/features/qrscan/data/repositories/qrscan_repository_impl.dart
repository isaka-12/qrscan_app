import 'package:qrscan_app/features/qrscan/data/datasources/qrscan_remote_datasource.dart';
import 'package:qrscan_app/features/qrscan/data/datasources/qrscan_local_datasource.dart';
import 'package:qrscan_app/features/qrscan/data/models/scan_model.dart';
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/domain/repositories/qrscan_repository.dart';

class QrScanRepositoryImpl implements QrScanRepository {
  final QrScanRemoteDataSource remoteDataSource;
  final QrScanLocalDataSource localDataSource;

  QrScanRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<void> saveScan(Scan scan) async {
    final scanModel = ScanModel.fromEntity(scan);

    // Save locally first (for offline capability)
    await localDataSource.insertScan(scanModel);

    // Try to save remotely (may fail if offline)
    try {
      await remoteDataSource.sendScan(scanModel);
    } catch (e) {
      // Log error or handle offline scenario
      // Could implement a queue for offline scans here
      // Note: In production, use proper logging instead of print
      // For now, silently handle offline scenario
    }
  }

  @override
  Future<List<Scan>> getAllScans() async {
    // Always get from local storage for faster access
    final scanModels = await localDataSource.getAllScans();
    return scanModels; // ScanModel extends Scan, so this is valid
  }

  @override
  Future<List<Scan>> searchScans(String query) async {
    final scanModels = await localDataSource.searchScans(query);
    return scanModels; // ScanModel extends Scan, so this is valid
  }

  @override
  Future<void> clearAllScans() async {
    await localDataSource.deleteAllScans();
    // Optionally clear remote data as well
  }

  @override
  Future<List<Scan>> getRecentScans(int limit) async {
    final scanModels = await localDataSource.getRecentScans(limit);
    return scanModels; // ScanModel extends Scan, so this is valid
  }
}
