import 'dart:convert';
import 'package:http/http.dart' as http;

class AirQualityData {
  final DateTime time;
  final double? pm25;
  final double? pm10;
  final double? ozone;
  final int? usAqi;
  final int? europeanAqi;

  AirQualityData({
    required this.time,
    this.pm25,
    this.pm10,
    this.ozone,
    this.usAqi,
    this.europeanAqi,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return AirQualityData(
      time: DateTime.parse(current['time']),
      pm25: (current['pm2_5'] as num?)?.toDouble(),
      pm10: (current['pm10'] as num?)?.toDouble(),
      ozone: (current['ozone'] as num?)?.toDouble(),
      usAqi: (current['us_aqi'] as num?)?.toInt(),
      europeanAqi: (current['european_aqi'] as num?)?.toInt(),
    );
  }
}

class AirQualityApi {
  static const _baseUrl = 'https://air-quality.open-meteo.com/v1/air-quality';

  Future<AirQualityData?> fetchAirQuality(double lat, double lon) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lon.toStringAsFixed(4),
        'current': 'us_aqi,european_aqi,pm10,pm2_5,ozone',
        'timezone': 'auto',
      });

      print('🌫️ AQI Request: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      print('📡 AQI HTTP Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('📄 AQI Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
        final data = json.decode(response.body);
        final result = AirQualityData.fromJson(data);
        print('✅ Parsed AQI - US: ${result.usAqi}, EU: ${result.europeanAqi}');
        return result;
      }
      
      print('⚠️ AQI API HTTP ${response.statusCode}: ${response.body}');
      return null;
    } catch (e, stackTrace) {
      print('❌ AQI Error: $e');
      print('Stack: ${stackTrace.toString().substring(0, 100)}');
      return null;
    }
  }
}
