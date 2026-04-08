
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/domain/repositories/qrscan_repository.dart';
// Use case for saving a scanned QR code using the repository.
class SaveScan {
  final QrScanRepository repository;

  SaveScan(this.repository);

  Future<void> call(Scan scan) async {
    return await repository.saveScan(scan);
  }
}
