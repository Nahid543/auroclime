import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/geocoding_api.dart';

class SearchService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 5;

  final _geocodingApi = GeocodingApi();

  Future<List<LocationResult>> searchLocations(String query) async {
    return await _geocodingApi.searchLocations(query);
  }

  Future<List<RecentSearch>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_recentSearchesKey) ?? [];
      
      return jsonList.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return RecentSearch(
          name: data['name'] as String,
          displayName: data['displayName'] as String,
          latitude: data['latitude'] as double,
          longitude: data['longitude'] as double,
          timestamp: DateTime.parse(data['timestamp'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecentSearch(LocationResult location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = await getRecentSearches();

      recent.removeWhere((item) => 
        item.latitude == location.latitude && 
        item.longitude == location.longitude
      );

      recent.insert(0, RecentSearch(
        name: location.name,
        displayName: location.displayName,
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now(),
      ));

      if (recent.length > _maxRecentSearches) {
        recent.removeRange(_maxRecentSearches, recent.length);
      }

      final jsonList = recent.map((item) {
        return jsonEncode({
          'name': item.name,
          'displayName': item.displayName,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'timestamp': item.timestamp.toIso8601String(),
        });
      }).toList();

      await prefs.setStringList(_recentSearchesKey, jsonList);
    } catch (_) {}
  }

  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (_) {}
  }

  void dispose() {
    _geocodingApi.dispose();
  }
}

class RecentSearch {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  RecentSearch({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
