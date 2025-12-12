import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingApi {
  GeocodingApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _baseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<List<LocationResult>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'name': query,
        'count': '10',
        'language': 'en',
        'format': 'json',
      },
    );

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to search locations');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        return [];
      }

      return results.map((item) {
        final data = item as Map<String, dynamic>;
        return LocationResult(
          name: data['name'] as String,
          country: data['country'] as String,
          admin1: data['admin1'] as String?,
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          countryCode: data['country_code'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception('Search failed: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}

class LocationResult {
  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final String? countryCode;

  LocationResult({
    required this.name,
    required this.country,
    this.admin1,
    required this.latitude,
    required this.longitude,
    this.countryCode,
  });

  String get displayName {
    if (admin1 != null && admin1!.isNotEmpty) {
      return '$name, $admin1, $country';
    }
    return '$name, $country';
  }

  String get shortName {
    return '$name, $country';
  }
}
