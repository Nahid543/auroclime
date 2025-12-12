import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavedLocationsService {
  static const String _savedLocationsKey = 'saved_locations';
  static const int _maxSavedLocations = 5;

  Future<List<SavedLocation>> getSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_savedLocationsKey) ?? [];
      
      return jsonList.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return SavedLocation(
          name: data['name'] as String,
          latitude: data['latitude'] as double,
          longitude: data['longitude'] as double,
          isCurrent: data['isCurrent'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveLocation(SavedLocation location) async {
    try {
      final locations = await getSavedLocations();
      
      if (locations.any((loc) => 
          loc.latitude == location.latitude && 
          loc.longitude == location.longitude)) {
        return false;
      }

      if (locations.where((loc) => !loc.isCurrent).length >= _maxSavedLocations) {
        return false;
      }

      locations.add(location);
      await _persistLocations(locations);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteLocation(SavedLocation location) async {
    try {
      final locations = await getSavedLocations();
      locations.removeWhere((loc) => 
        loc.latitude == location.latitude && 
        loc.longitude == location.longitude
      );
      await _persistLocations(locations);
    } catch (_) {}
  }

  Future<void> updateCurrentLocation(double latitude, double longitude, String name) async {
    try {
      final locations = await getSavedLocations();
      
      locations.removeWhere((loc) => loc.isCurrent);
      
      locations.insert(0, SavedLocation(
        name: name,
        latitude: latitude,
        longitude: longitude,
        isCurrent: true,
      ));

      await _persistLocations(locations);
    } catch (_) {}
  }

  Future<void> clearCurrentLocation() async {
    try {
      final locations = await getSavedLocations();
      locations.removeWhere((loc) => loc.isCurrent);
      await _persistLocations(locations);
    } catch (_) {}
  }

  Future<void> _persistLocations(List<SavedLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = locations.map((loc) {
      return jsonEncode({
        'name': loc.name,
        'latitude': loc.latitude,
        'longitude': loc.longitude,
        'isCurrent': loc.isCurrent,
      });
    }).toList();
    await prefs.setStringList(_savedLocationsKey, jsonList);
  }

  Future<int> getSavedLocationsCount() async {
    final locations = await getSavedLocations();
    return locations.where((loc) => !loc.isCurrent).length;
  }

  bool canSaveMore(int currentCount) {
    return currentCount < _maxSavedLocations;
  }
}

class SavedLocation {
  final String name;
  final double latitude;
  final double longitude;
  final bool isCurrent;

  SavedLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isCurrent = false,
  });

  String get displayName => name;
  
  String get locationKey => '${latitude}_$longitude';
}
