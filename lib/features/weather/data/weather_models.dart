import 'package:intl/intl.dart';

/// Snapshot of current weather, hourly and daily forecast.
class WeatherSnapshot {
  WeatherSnapshot({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentConditions current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    final dailyJson = json['daily'] as Map<String, dynamic>;
    final dailyTimes = List<String>.from(dailyJson['time'] as List);

    final List<DailyForecast> daily = List.generate(dailyTimes.length, (index) {
      return DailyForecast(
        date: DateTime.parse(dailyTimes[index]),
        minTemp:
            (dailyJson['temperature_2m_min'][index] as num).toDouble(),
        maxTemp:
            (dailyJson['temperature_2m_max'][index] as num).toDouble(),
        weatherCode: dailyJson['weathercode'][index] as int,
        precipitationProbability:
            (dailyJson['precipitation_probability_max'][index] as num)
                .toInt(),
        sunrise: dailyJson['sunrise']?[index] != null
            ? DateTime.parse(dailyJson['sunrise'][index] as String)
            : null,
        sunset: dailyJson['sunset']?[index] != null
            ? DateTime.parse(dailyJson['sunset'][index] as String)
            : null,
        uvIndexMax: dailyJson['uv_index_max']?[index] != null
            ? (dailyJson['uv_index_max'][index] as num).toDouble()
            : null,
      );
    });

    final hourlyJson = json['hourly'] as Map<String, dynamic>;
    final hourlyTimes = List<String>.from(hourlyJson['time'] as List);

    final List<HourlyForecast> hourly =
        List.generate(hourlyTimes.length, (index) {
      return HourlyForecast(
        time: DateTime.parse(hourlyTimes[index]),
        temperature:
            (hourlyJson['temperature_2m'][index] as num).toDouble(),
        precipitationProbability:
            (hourlyJson['precipitation_probability'][index] as num)
                .toInt(),
        apparentTemperature: hourlyJson['apparent_temperature']?[index] != null
            ? (hourlyJson['apparent_temperature'][index] as num).toDouble()
            : null,
        uvIndex: hourlyJson['uv_index']?[index] != null
            ? (hourlyJson['uv_index'][index] as num).toDouble()
            : null,
        visibility: hourlyJson['visibility']?[index] != null
            ? (hourlyJson['visibility'][index] as num).toDouble()
            : null,
        isDay: hourlyJson['is_day']?[index] != null
            ? (hourlyJson['is_day'][index] as num) == 1
            : null,
      );
    });

    return WeatherSnapshot(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      current: CurrentConditions.fromJson(
        json['current_weather'] as Map<String, dynamic>,
      ),
      hourly: hourly,
      daily: daily,
    );
  }
}

/// Current conditions from Open-Meteo.
class CurrentConditions {
  CurrentConditions({
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherCode,
    required this.isDay,
    this.apparentTemperature,
    this.uvIndex,
    this.visibility,
    this.pressure,
    this.dewPoint,
  });

  final DateTime time;
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final int weatherCode;
  final bool isDay;
  final double? apparentTemperature;
  final double? uvIndex;
  final double? visibility;
  final double? pressure;
  final double? dewPoint;

  factory CurrentConditions.fromJson(Map<String, dynamic> json) {
    return CurrentConditions(
      time: DateTime.parse(json['time'] as String),
      temperature: (json['temperature'] as num).toDouble(),
      windSpeed: (json['windspeed'] as num).toDouble(),
      windDirection: (json['winddirection'] as num).toDouble(),
      weatherCode: json['weathercode'] as int,
      isDay: (json['is_day'] as num) == 1,
      apparentTemperature: json['apparent_temperature'] != null
          ? (json['apparent_temperature'] as num).toDouble()
          : null,
      uvIndex:
          json['uv_index'] != null ? (json['uv_index'] as num).toDouble() : null,
      visibility: json['visibility'] != null
          ? (json['visibility'] as num).toDouble()
          : null,
      pressure: json['surface_pressure'] != null
          ? (json['surface_pressure'] as num).toDouble()
          : null,
      dewPoint: json['dewpoint_2m'] != null
          ? (json['dewpoint_2m'] as num).toDouble()
          : null,
    );
  }
}

/// Hourly forecast rows for the next hours.
class HourlyForecast {
  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    this.apparentTemperature,
    this.uvIndex,
    this.visibility,
    this.isDay,
  });

  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final double? apparentTemperature;
  final double? uvIndex;
  final double? visibility;
  final bool? isDay;

  String get formattedHour => DateFormat.Hm().format(time);
}

/// Daily forecast rows for the next days.
class DailyForecast {
  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherCode,
    required this.precipitationProbability,
    this.sunrise,
    this.sunset,
    this.uvIndexMax,
  });

  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int weatherCode;
  final int precipitationProbability;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double? uvIndexMax;

  String get formattedDay {
    return DateFormat.E().format(date); // Mon, Tue, etc.
  }
}

/// Mapping from Open-Meteo weather codes to text.
String describeWeatherCode(int code) {
  if (code == 0) return 'Clear sky';
  if (code == 1 || code == 2 || code == 3) return 'Partly cloudy';
  if (code == 45 || code == 48) return 'Foggy';
  if (code == 51 || code == 53 || code == 55) return 'Drizzle';
  if (code == 61 || code == 63 || code == 65) return 'Rain';
  if (code == 66 || code == 67) return 'Freezing rain';
  if (code == 71 || code == 73 || code == 75) return 'Snow';
  if (code == 80 || code == 81 || code == 82) return 'Rain showers';
  if (code == 95) return 'Thunderstorm';
  if (code == 96 || code == 99) return 'Thunderstorm with hail';
  return 'Unknown';
}
