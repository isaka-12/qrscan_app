// lib/src/features/qrscan/data/datasources/qrscan_remote_datasource.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:qrscan_app/features/qrscan/data/models/scan_model.dart';

class QrScanRemoteDataSource {
  final http.Client client;

  QrScanRemoteDataSource(this.client);

  Future<void> sendScan(ScanModel scan) async {
    final response = await client.post(
      Uri.parse("https://your-backend.com/api/scans"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(scan.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to send scan");
    }
  }
}
