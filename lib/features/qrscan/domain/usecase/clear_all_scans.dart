// lib/features/qrscan/domain/usecase/clear_all_scans.dart
import '../repositories/qrscan_repository.dart';

class ClearAllScans {
  final QrScanRepository repository;

  ClearAllScans(this.repository);

  Future<void> call() async {
    return await repository.clearAllScans();
  }
}
