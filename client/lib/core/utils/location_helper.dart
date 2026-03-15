import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class LocationHelper {
  static Future<Position?> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    final denied = await Geolocator.checkPermission() == LocationPermission.denied;
    if (denied) {
      final status = await Geolocator.requestPermission();
      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        return null;
      }
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  /// Open Google Maps with directions from current location to [lat], [lng].
  static Future<void> openInMaps(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Approximate distance in km (Haversine).
  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
