import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  Position? _lastKnownPosition;

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<bool> isLocationPermissionGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied');
        return null;
      }

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location service is disabled');
        return null;
      }

      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      await _saveLocation(_lastKnownPosition);
      return _lastKnownPosition;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<Position?> getLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble('last_latitude');
    final longitude = prefs.getDouble('last_longitude');

    if (latitude != null && longitude != null) {
      _lastKnownPosition = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      return _lastKnownPosition;
    }
    return await getCurrentLocation();
  }

  Future<void> _saveLocation(Position? position) async {
    if (position == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', position.latitude);
    await prefs.setDouble('last_longitude', position.longitude);
  }
}