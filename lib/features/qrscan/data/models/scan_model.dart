// Model class for Scan, extending the Scan entity and providing JSON serialization/deserialization.
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';

class ScanModel extends Scan {
  ScanModel({
    required super.qrData,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    required super.address,
  });

  Map<String, dynamic> toJson() => {
    "qr_data": qrData,
    "timestamp": timestamp.toIso8601String(),
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
  };

  factory ScanModel.fromJson(Map<String, dynamic> json) => ScanModel(
    qrData: json["qr_data"],
    timestamp: DateTime.parse(json["timestamp"]),
    latitude: json["latitude"],
    longitude: json["longitude"],
    address: json["address"],
  );

  factory ScanModel.fromEntity(Scan scan) => ScanModel(
    qrData: scan.qrData,
    timestamp: scan.timestamp,
    latitude: scan.latitude,
    longitude: scan.longitude,
    address: scan.address,
  );

  factory ScanModel.fromMap(Map<String, dynamic> map) => ScanModel(
    qrData: map['qr_data'],
    timestamp: DateTime.parse(map['timestamp']),
    latitude: map['latitude'],
    longitude: map['longitude'],
    address: map['address'],
  );

  Map<String, dynamic> toMap() => {
    'qr_data': qrData,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };
}
