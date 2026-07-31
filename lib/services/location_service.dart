import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check and request location permissions.
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[Location] Location services disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[Location] Permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[Location] Permission permanently denied');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[Location] Permission error: $e');
      return false;
    }
  }

  /// Get current position. Returns null if failed or timed out.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          // Don't hang forever if GPS can't get a fix.
          timeLimit: Duration(seconds: 10),
        ),
      );
      return position;
    } catch (e) {
      debugPrint('[Location] Get position error: $e');
      return null;
    }
  }

  /// Generate an auto-fill address string from coordinates.
  /// When offline, uses formatted coordinates.
  /// When online, could be extended to call reverse geocoding API.
  static String addressFromCoordinates(double latitude, double longitude) {
    return 'Lokasi: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
