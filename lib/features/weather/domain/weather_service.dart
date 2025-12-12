import 'package:intl/intl.dart';

import '../data/air_quality_api.dart';
import '../data/open_meteo_api.dart';
import '../data/weather_models.dart';
import 'auroclime_tips.dart';

class WeatherService {
  WeatherService({
    OpenMeteoApi? api,
    AirQualityApi? airQualityApi,
  })  : _api = api ?? OpenMeteoApi(),
        _airQualityApi = airQualityApi ?? AirQualityApi();

  final OpenMeteoApi _api;
  final AirQualityApi _airQualityApi;

  Future<UIWeatherSnapshot> fetchWeatherForLocation({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    final snapshot = await _api.fetchWeather(
      latitude: latitude,
      longitude: longitude,
    );

    final rawCurrent = snapshot.current;
    final current = _mapCurrentWeather(rawCurrent);

    final tipResult = AuroclimeTipEngine.fromWeather(
      current: rawCurrent,
      humidityOverride: current.humidity,
      rainProbabilityOverride: snapshot.hourly.isNotEmpty
          ? snapshot.hourly.first.precipitationProbability
          : null,
    );

    final airQuality = await _fetchAirQuality(latitude, longitude);
    final alerts = _generateSyntheticAlerts(rawCurrent);

    print('🏠 Weather snapshot: AQI = ${airQuality != null ? "${airQuality.aqi} (${airQuality.category})" : "NULL"}');

    return UIWeatherSnapshot(
      locationName: locationName,
      dateText: _formatDate(DateTime.now()),
      lastUpdatedText: _formatTime(snapshot.current.time),
      footerStatusText:
          'Last sync: ${_formatTime(DateTime.now())} · Auto-updating every 30 min',
      current: current,
      hourly: _mapHourlyWeather(snapshot.hourly),
      daily: _mapDailyWeather(snapshot.daily),
      tip: UITip(
        message: tipResult.message,
        comfortLevel: tipResult.comfortLevel.label,
        comfortEmoji: tipResult.comfortLevel.emoji,
      ),
      airQuality: airQuality,
      alerts: alerts,
    );
  }

  Future<UIAirQuality?> _fetchAirQuality(double lat, double lon) async {
    try {
      print('🌫️ Fetching AQI for ($lat, $lon)');
      final data = await _airQualityApi.fetchAirQuality(lat, lon);
      if (data == null) {
        print('⚠️ AQI API returned null');
        return null;
      }

      final aqi = data.usAqi ?? data.europeanAqi ?? 0;
      print('📊 AQI value: $aqi (US: ${data.usAqi}, EU: ${data.europeanAqi})');
      if (aqi == 0) {
        print('⚠️ AQI is 0, returning null');
        return null;
      }

      final AQILevel level;
      final String category;
      final String advice;

      if (aqi <= 50) {
        level = AQILevel.good;
        category = 'Good';
        advice = 'Air quality is ideal for outdoor activities.';
      } else if (aqi <= 100) {
        level = AQILevel.moderate;
        category = 'Moderate';
        advice = 'Acceptable air quality for most people.';
      } else if (aqi <= 150) {
        level = AQILevel.unhealthySensitive;
        category = 'Unhealthy for Sensitive Groups';
        advice = 'Sensitive individuals should limit prolonged outdoor exertion.';
      } else if (aqi <= 200) {
        level = AQILevel.unhealthy;
        category = 'Unhealthy';
        advice = 'Everyone should reduce outdoor activities.';
      } else if (aqi <= 300) {
        level = AQILevel.veryUnhealthy;
        category = 'Very Unhealthy';
        advice = 'Avoid outdoor activities. Health alert in effect.';
      } else {
        level = AQILevel.hazardous;
        category = 'Hazardous';
        advice = 'Stay indoors. Emergency health warnings.';
      }

      String primaryPollutant = 'PM2.5';
      double maxValue = data.pm25 ?? 0;

      if ((data.pm10 ?? 0) > maxValue) {
        primaryPollutant = 'PM10';
        maxValue = data.pm10!;
      }
      if ((data.ozone ?? 0) > maxValue * 0.5) {
        primaryPollutant = 'Ozone';
      }

      print('✅ Returning AQI: $aqi ($category) - $primaryPollutant');
      return UIAirQuality(
        aqi: aqi,
        level: level,
        category: category,
        advice: advice,
        primaryPollutant: primaryPollutant,
      );
    } catch (e) {
      print('❌ AQI fetch error: $e');
      return null;
    }
  }

  UICurrentWeather _mapCurrentWeather(CurrentConditions current) {
    return UICurrentWeather(
      temperature: current.temperature.round(),
      feelsLike: current.apparentTemperature?.round() ?? current.temperature.round(),
      humidity: 78,
      windKph: current.windSpeed,
      condition: _mapWeatherCode(current.weatherCode, current.isDay),
      weatherDescription: describeWeatherCode(current.weatherCode),
      weatherCode: current.weatherCode,
      uvIndex: current.uvIndex,
      visibility: current.visibility,
      pressure: current.pressure,
      dewPoint: current.dewPoint,
    );
  }

  List<UIHourlyWeather> _mapHourlyWeather(List<HourlyForecast> hourly) {
    final now = DateTime.now();
    return hourly
        .where((h) => h.time.isAfter(now))
        .take(12)
        .map(
          (h) => UIHourlyWeather(
            timeLabel: h.formattedHour,
            temperature: h.temperature.round(),
            rainChance: h.precipitationProbability,
            condition: WeatherCondition.partlyCloudy,
          ),
        )
        .toList();
  }

  List<UIDailyWeather> _mapDailyWeather(List<DailyForecast> daily) {
    return daily.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      return UIDailyWeather(
        dayLabel: index == 0 ? 'Today' : day.formattedDay,
        summary: describeWeatherCode(day.weatherCode),
        high: day.maxTemp.round(),
        low: day.minTemp.round(),
        condition: _mapWeatherCode(day.weatherCode, true),
        sunrise: day.sunrise,
        sunset: day.sunset,
        uvIndexMax: day.uvIndexMax,
      );
    }).toList();
  }

  List<UIWeatherAlert> _generateSyntheticAlerts(CurrentConditions current) {
    final alerts = <UIWeatherAlert>[];
    final code = current.weatherCode;
    final now = DateTime.now();

    if (code >= 95) {
      alerts.add(
        UIWeatherAlert(
          id: 'thunder_${now.millisecondsSinceEpoch}',
          title: code == 99
              ? 'Severe Thunderstorm Warning'
              : 'Thunderstorm Watch',
          description: code == 99
              ? 'Severe thunderstorm with hail detected. Take shelter immediately and stay away from windows.'
              : 'Thunderstorm activity in your area. Monitor conditions and stay indoors if possible.',
          severity: code == 99 ? AlertSeverity.extreme : AlertSeverity.severe,
          startsAt: now,
          endsAt: now.add(const Duration(hours: 2)),
        ),
      );
    }

    if ((code >= 56 && code <= 57) || (code >= 66 && code <= 67)) {
      alerts.add(
        UIWeatherAlert(
          id: 'freeze_${now.millisecondsSinceEpoch}',
          title: 'Freezing Precipitation Advisory',
          description:
              'Freezing rain or drizzle may create hazardous ice on roads and sidewalks. Use extreme caution when traveling.',
          severity: AlertSeverity.moderate,
          startsAt: now,
          endsAt: now.add(const Duration(hours: 4)),
        ),
      );
    }

    if (current.temperature >= 38) {
      alerts.add(
        UIWeatherAlert(
          id: 'heat_${now.millisecondsSinceEpoch}',
          title: 'Extreme Heat Warning',
          description:
              'Dangerously hot conditions. Stay hydrated, avoid outdoor activity during peak hours, and check on vulnerable individuals.',
          severity: AlertSeverity.severe,
          startsAt: now,
          endsAt: now.add(const Duration(hours: 12)),
        ),
      );
    }

    if (current.temperature <= -10) {
      alerts.add(
        UIWeatherAlert(
          id: 'cold_${now.millisecondsSinceEpoch}',
          title: 'Extreme Cold Warning',
          description:
              'Dangerously cold temperatures. Frostbite and hypothermia risk. Limit outdoor exposure and dress in layers.',
          severity: AlertSeverity.severe,
          startsAt: now,
          endsAt: now.add(const Duration(hours: 12)),
        ),
      );
    }

    if (current.windSpeed >= 50) {
      alerts.add(
        UIWeatherAlert(
          id: 'wind_${now.millisecondsSinceEpoch}',
          title: 'High Wind Warning',
          description:
              'Damaging winds detected. Secure loose objects and avoid travel if possible. Power outages may occur.',
          severity: AlertSeverity.moderate,
          startsAt: now,
          endsAt: now.add(const Duration(hours: 6)),
        ),
      );
    }

    return alerts;
  }

  WeatherCondition _mapWeatherCode(int code, bool isDay) {
    if (code == 0) {
      return isDay ? WeatherCondition.clear : WeatherCondition.night;
    }
    if (code <= 3) return WeatherCondition.partlyCloudy;
    if (code <= 48) return WeatherCondition.cloudy;
    if (code <= 67) return WeatherCondition.rain;
    if (code <= 82) return WeatherCondition.rain;
    return WeatherCondition.thunderstorm;
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  void dispose() {
    _api.dispose();
  }
}

class UIWeatherSnapshot {
  final String locationName;
  final String dateText;
  final String lastUpdatedText;
  final String footerStatusText;
  final UICurrentWeather current;
  final List<UIHourlyWeather> hourly;
  final List<UIDailyWeather> daily;
  final UITip tip;
  final UIAirQuality? airQuality;
  final List<UIWeatherAlert> alerts;

  UIWeatherSnapshot({
    required this.locationName,
    required this.dateText,
    required this.lastUpdatedText,
    required this.footerStatusText,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.tip,
    this.airQuality,
    this.alerts = const [],
  });
}

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  rain,
  thunderstorm,
  night,
}

class UICurrentWeather {
  final int temperature;
  final int feelsLike;
  final int humidity;
  final double windKph;
  final WeatherCondition condition;
  final String weatherDescription;
  final int weatherCode;
  final double? uvIndex;
  final double? visibility;
  final double? pressure;
  final double? dewPoint;

  UICurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windKph,
    required this.condition,
    required this.weatherDescription,
    required this.weatherCode,
    this.uvIndex,
    this.visibility,
    this.pressure,
    this.dewPoint,
  });
}

class UIHourlyWeather {
  final String timeLabel;
  final int temperature;
  final int rainChance;
  final WeatherCondition condition;

  UIHourlyWeather({
    required this.timeLabel,
    required this.temperature,
    required this.rainChance,
    required this.condition,
  });
}

class UIDailyWeather {
  final String dayLabel;
  final String summary;
  final int high;
  final int low;
  final WeatherCondition condition;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double? uvIndexMax;

  UIDailyWeather({
    required this.dayLabel,
    required this.summary,
    required this.high,
    required this.low,
    required this.condition,
    this.sunrise,
    this.sunset,
    this.uvIndexMax,
  });
}

class UITip {
  final String message;
  final String comfortLevel;
  final String comfortEmoji;

  UITip({
    required this.message,
    required this.comfortLevel,
    required this.comfortEmoji,
  });
}

class UIAirQuality {
  final int aqi;
  final AQILevel level;
  final String category;
  final String advice;
  final String primaryPollutant;

  UIAirQuality({
    required this.aqi,
    required this.level,
    required this.category,
    required this.advice,
    required this.primaryPollutant,
  });
}

enum AQILevel {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous;

  String get displayName {
    switch (this) {
      case AQILevel.good:
        return 'Good';
      case AQILevel.moderate:
        return 'Moderate';
      case AQILevel.unhealthySensitive:
        return 'Unhealthy for Sensitive Groups';
      case AQILevel.unhealthy:
        return 'Unhealthy';
      case AQILevel.veryUnhealthy:
        return 'Very Unhealthy';
      case AQILevel.hazardous:
        return 'Hazardous';
    }
  }
}

class UIWeatherAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime startsAt;
  final DateTime endsAt;

  UIWeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.startsAt,
    required this.endsAt,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }
}

enum AlertSeverity {
  minor,
  moderate,
  severe,
  extreme;

  String get displayName {
    switch (this) {
      case AlertSeverity.minor:
        return 'Minor';
      case AlertSeverity.moderate:
        return 'Moderate';
      case AlertSeverity.severe:
        return 'Severe';
      case AlertSeverity.extreme:
        return 'Extreme';
    }
  }
}
