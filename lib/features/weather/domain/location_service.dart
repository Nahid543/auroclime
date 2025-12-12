import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _latKey = 'cached_latitude';
  static const String _lonKey = 'cached_longitude';
  static const String _cityKey = 'cached_city_name';

  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check and request permission FIRST (before checking if service is enabled)
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final cached = await getCachedLocation();
          if (cached != null) return cached;
          return LocationResult.permissionDenied();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final cached = await getCachedLocation();
        if (cached != null) return cached;
        return LocationResult.permissionDeniedForever();
      }

      // NOW check if location service is enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        final cached = await getCachedLocation();
        if (cached != null) return cached;
        return LocationResult.serviceDisabled();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      final cityName = await _getCityName(position.latitude, position.longitude);

      await _cacheLocation(position.latitude, position.longitude, cityName);

      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName,
      );
    } catch (e) {
      final cached = await getCachedLocation();
      if (cached != null) return cached;
      return LocationResult.error('Unable to get your location');
    }
  }

  Future<String> _getCityName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
        final country = place.country ?? '';
        return country.isNotEmpty ? '$city, $country' : city;
      }
    } catch (e) {
      return 'Lat ${latitude.toStringAsFixed(1)}, Lon ${longitude.toStringAsFixed(1)}';
    }
    return 'Unknown Location';
  }

  Future<void> _cacheLocation(
    double latitude,
    double longitude,
    String cityName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, latitude);
      await prefs.setDouble(_lonKey, longitude);
      await prefs.setString(_cityKey, cityName);
    } catch (_) {}
  }

  Future<LocationResult?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_latKey);
      final lon = prefs.getDouble(_lonKey);
      final city = prefs.getString(_cityKey);

      if (lat != null && lon != null && city != null) {
        return LocationResult.success(
          latitude: lat,
          longitude: lon,
          cityName: city,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_latKey);
      await prefs.remove(_lonKey);
      await prefs.remove(_cityKey);
    } catch (_) {}
  }
}

class LocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final String? cityName;
  final String? errorMessage;
  final LocationErrorType? errorType;

  LocationResult._({
    required this.success,
    this.latitude,
    this.longitude,
    this.cityName,
    this.errorMessage,
    this.errorType,
  });

  factory LocationResult.success({
    required double latitude,
    required double longitude,
    required String cityName,
  }) {
    return LocationResult._(
      success: true,
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
    );
  }

  factory LocationResult.serviceDisabled() {
    return LocationResult._(
      success: false,
      errorMessage: 'Location services are disabled. Please enable GPS in settings.',
      errorType: LocationErrorType.serviceDisabled,
    );
  }

  factory LocationResult.permissionDenied() {
    return LocationResult._(
      success: false,
      errorMessage: 'Location permission denied. Please grant permission to use this app.',
      errorType: LocationErrorType.permissionDenied,
    );
  }

  factory LocationResult.permissionDeniedForever() {
    return LocationResult._(
      success: false,
      errorMessage: 'Location permission permanently denied. Please enable in app settings.',
      errorType: LocationErrorType.permissionDeniedForever,
    );
  }

  factory LocationResult.error(String message) {
    return LocationResult._(
      success: false,
      errorMessage: message,
      errorType: LocationErrorType.unknown,
    );
  }
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}
