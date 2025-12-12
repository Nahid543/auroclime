import 'dart:convert';

import 'package:http/http.dart' as http;

import 'weather_models.dart';

class OpenMeteoApi {
  OpenMeteoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherSnapshot> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: <String, String>{
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current_weather': 'true',
        'hourly': 'temperature_2m,precipitation_probability,apparent_temperature,uv_index,visibility,surface_pressure,dewpoint_2m,is_day',
        'daily':
            'weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max',
        'timezone': 'auto',
      },
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load weather (${response.statusCode})');
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    return WeatherSnapshot.fromJson(json);
  }

  void dispose() {
    _client.close();
  }
}
