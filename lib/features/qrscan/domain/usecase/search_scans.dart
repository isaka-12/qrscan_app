// lib/features/qrscan/domain/usecase/search_scans.dart
import '../entities/scan.dart';
import '../repositories/qrscan_repository.dart';

class SearchScans {
  final QrScanRepository repository;

  SearchScans(this.repository);

  Future<List<Scan>> call(String query) async {
    return await repository.searchScans(query);
  }
}
