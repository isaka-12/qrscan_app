
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// Helper class for obtaining the current location and address.
class LocationHelper {

  // Get the current latitude, longitude, and address as a tuple.
  static Future<(double, double, String)> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location service disabled");

    // Check and request location permissions.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied forever");
    }

    // Get the current position with high accuracy.
    final position = await Geolocator.getCurrentPosition(
     //using settings: LocationSettings(accuracy: LocationAccuracy.high)
     locationSettings: LocationSettings(accuracy: LocationAccuracy.high)
    );

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    String address = placemarks.isNotEmpty
        ? "${placemarks.first.locality}, ${placemarks.first.country}"
        : "Unknown location";

    return (position.latitude, position.longitude, address);
  }
}
