import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/domain/repositories/qrscan_repository.dart';

// Use case for deleting one scan.
class DeleteScan {
  final QrScanRepository repository;

  DeleteScan(this.repository);

  Future<void> call(Scan scan) => repository.deleteScan(scan);
}
