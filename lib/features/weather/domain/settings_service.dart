import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _tempUnitKey = 'temperature_unit';
  static const String _refreshIntervalKey = 'refresh_interval';
  static const String _windSpeedUnitKey = 'wind_speed_unit'; // NEW

  Future<TemperatureUnit> getTemperatureUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_tempUnitKey);
      if (value == 'fahrenheit') return TemperatureUnit.fahrenheit;
      return TemperatureUnit.celsius;
    } catch (_) {
      return TemperatureUnit.celsius;
    }
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tempUnitKey,
        unit == TemperatureUnit.celsius ? 'celsius' : 'fahrenheit',
      );
    } catch (_) {}
  }

  Future<RefreshInterval> getRefreshInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final minutes = prefs.getInt(_refreshIntervalKey) ?? 30;
      return RefreshInterval.values.firstWhere(
        (e) => e.minutes == minutes,
        orElse: () => RefreshInterval.thirtyMinutes,
      );
    } catch (_) {
      return RefreshInterval.thirtyMinutes;
    }
  }

  Future<void> setRefreshInterval(RefreshInterval interval) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_refreshIntervalKey, interval.minutes);
    } catch (_) {}
  }

  // NEW: Wind Speed Unit Methods
  Future<WindSpeedUnit> getWindSpeedUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_windSpeedUnitKey);
      if (value == 'mph') return WindSpeedUnit.mph;
      if (value == 'ms') return WindSpeedUnit.ms;
      return WindSpeedUnit.kmh;
    } catch (_) {
      return WindSpeedUnit.kmh;
    }
  }

  Future<void> setWindSpeedUnit(WindSpeedUnit unit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String value = 'kmh';
      if (unit == WindSpeedUnit.mph) value = 'mph';
      if (unit == WindSpeedUnit.ms) value = 'ms';
      await prefs.setString(_windSpeedUnitKey, value);
    } catch (_) {}
  }

  // Temperature Conversions
  int celsiusToFahrenheit(int celsius) {
    return (celsius * 9 / 5 + 32).round();
  }

  double celsiusToFahrenheitDouble(double celsius) {
    return celsius * 9 / 5 + 32;
  }

  String formatTemperature(int temp, TemperatureUnit unit) {
    if (unit == TemperatureUnit.fahrenheit) {
      return '${celsiusToFahrenheit(temp)}°F';
    }
    return '$temp°C';
  }

  String formatTemperatureSimple(int temp, TemperatureUnit unit) {
    if (unit == TemperatureUnit.fahrenheit) {
      return '${celsiusToFahrenheit(temp)}°';
    }
    return '$temp°';
  }

  // NEW: Wind Speed Conversions
  double convertWindSpeed(double kmh, WindSpeedUnit unit) {
    switch (unit) {
      case WindSpeedUnit.kmh:
        return kmh;
      case WindSpeedUnit.mph:
        return kmh * 0.621371;
      case WindSpeedUnit.ms:
        return kmh * 0.277778;
    }
  }

  String formatWindSpeed(double kmh, WindSpeedUnit unit) {
    final converted = convertWindSpeed(kmh, unit);
    return '${converted.toStringAsFixed(1)} ${unit.symbol}';
  }
}

enum TemperatureUnit {
  celsius,
  fahrenheit;

  String get symbol => this == celsius ? '°C' : '°F';
  String get label => this == celsius ? 'Celsius' : 'Fahrenheit';
}

enum RefreshInterval {
  fifteenMinutes(15, '15 minutes'),
  thirtyMinutes(30, '30 minutes'),
  sixtyMinutes(60, '60 minutes');

  final int minutes;
  final String label;

  const RefreshInterval(this.minutes, this.label);
}

// NEW: Wind Speed Unit Enum
enum WindSpeedUnit {
  kmh,
  mph,
  ms;

  String get symbol {
    switch (this) {
      case WindSpeedUnit.kmh:
        return 'km/h';
      case WindSpeedUnit.mph:
        return 'mph';
      case WindSpeedUnit.ms:
        return 'm/s';
    }
  }

  String get label {
    switch (this) {
      case WindSpeedUnit.kmh:
        return 'Kilometers per hour (km/h)';
      case WindSpeedUnit.mph:
        return 'Miles per hour (mph)';
      case WindSpeedUnit.ms:
        return 'Meters per second (m/s)';
    }
  }

  String get shortLabel {
    switch (this) {
      case WindSpeedUnit.kmh:
        return 'km/h (Metric)';
      case WindSpeedUnit.mph:
        return 'mph (Imperial)';
      case WindSpeedUnit.ms:
        return 'm/s (Scientific)';
    }
  }
}
