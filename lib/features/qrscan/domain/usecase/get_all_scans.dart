// lib/features/qrscan/domain/usecase/get_all_scans.dart
import '../entities/scan.dart';
import '../repositories/qrscan_repository.dart';

class GetAllScans {
  final QrScanRepository repository;

  GetAllScans(this.repository);

  Future<List<Scan>> call() async {
    return await repository.getAllScans();
  }
}
