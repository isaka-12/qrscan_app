// Represents a scanned QR code with associated metadata.
class Scan {
  final String qrData;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String address;

  // Constructor for creating a Scan instance.

  Scan({
    required this.qrData,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}
