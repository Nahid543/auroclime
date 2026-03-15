import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'settings_service.dart';
import 'weather_service.dart';

/// Bridges Flutter weather data → Android home screen widget via SharedPreferences.
///
/// The native [AuroclimeWidgetProvider] reads these keys to populate RemoteViews.
class WidgetService {
  static const String _androidWidgetName = 'AuroclimeWidgetProvider';
  
  // Singleton SettingsService instance for better performance
  static final SettingsService _settings = SettingsService();

  static UIWeatherSnapshot? _latestSnapshot;
  static TemperatureUnit? _latestUnit;

  /// Saves the latest weather snapshot to SharedPreferences and triggers
  /// a native widget update.
  static Future<void> updateWidget(
    UIWeatherSnapshot snapshot,
    TemperatureUnit tempUnit,
  ) async {
    try {
      _latestSnapshot = snapshot;
      _latestUnit = tempUnit;

      // Current conditions
      final temp = tempUnit == TemperatureUnit.fahrenheit
          ? _settings.celsiusToFahrenheit(snapshot.current.temperature)
          : snapshot.current.temperature;
      final feelsLike = tempUnit == TemperatureUnit.fahrenheit
          ? _settings.celsiusToFahrenheit(snapshot.current.feelsLike)
          : snapshot.current.feelsLike;
      final unitSymbol = tempUnit == TemperatureUnit.celsius ? '°C' : '°F';

      // High/Low from today's daily forecast
      int high = temp;
      int low = temp;
      if (snapshot.daily.isNotEmpty) {
        high = tempUnit == TemperatureUnit.fahrenheit
            ? _settings.celsiusToFahrenheit(snapshot.daily.first.high)
            : snapshot.daily.first.high;
        low = tempUnit == TemperatureUnit.fahrenheit
            ? _settings.celsiusToFahrenheit(snapshot.daily.first.low)
            : snapshot.daily.first.low;
      }

      // Save all widget keys in parallel
      await Future.wait([
        HomeWidget.saveWidgetData('widget_location', snapshot.locationName),
        HomeWidget.saveWidgetData('widget_temp', '$temp$unitSymbol'),
        HomeWidget.saveWidgetData(
          'widget_condition',
          snapshot.current.weatherDescription,
        ),
        HomeWidget.saveWidgetData(
          'widget_condition_icon',
          _weatherConditionToIconName(snapshot.current.condition),
        ),
        HomeWidget.saveWidgetData('widget_high', 'H:$high°'),
        HomeWidget.saveWidgetData('widget_low', 'L:$low°'),
        HomeWidget.saveWidgetData('widget_feels_like', 'Feels $feelsLike°'),
        HomeWidget.saveWidgetData(
          'widget_updated_at',
          DateFormat.jm().format(DateTime.now()),
        ),
      ]);

      // Save hourly forecast (next 4 hours) in parallel
      final hourly = snapshot.hourly.take(4).toList();
      final hourlyFutures = <Future<void>>[];
      
      for (int i = 0; i < 4; i++) {
        if (i < hourly.length) {
          final hTemp = tempUnit == TemperatureUnit.fahrenheit
              ? _settings.celsiusToFahrenheit(hourly[i].temperature)
              : hourly[i].temperature;
          hourlyFutures.addAll([
            HomeWidget.saveWidgetData(
              'widget_hourly_time_$i',
              hourly[i].timeLabel,
            ),
            HomeWidget.saveWidgetData(
              'widget_hourly_icon_$i',
              _weatherConditionToIconName(hourly[i].condition),
            ),
            HomeWidget.saveWidgetData(
              'widget_hourly_temp_$i',
              '$hTemp°',
            ),
          ]);
        } else {
          hourlyFutures.addAll([
            HomeWidget.saveWidgetData('widget_hourly_time_$i', '--'),
            HomeWidget.saveWidgetData('widget_hourly_icon_$i', 'ic_widget_cloudy'),
            HomeWidget.saveWidgetData('widget_hourly_temp_$i', '--'),
          ]);
        }
      }
      
      await Future.wait(hourlyFutures);

      // Trigger native widget repaint
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // Widget update is non-critical — never crash the app for it.
      print('⚠️ Widget update failed: $e');
    }
  }

  /// Maps WeatherCondition enum to an Android VectorDrawable resource name.
  static String _weatherConditionToIconName(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return 'ic_widget_clear';
      case WeatherCondition.partlyCloudy:
        return 'ic_widget_cloudy';
      case WeatherCondition.cloudy:
        return 'ic_widget_cloudy';
      case WeatherCondition.rain:
        return 'ic_widget_rain';
      case WeatherCondition.thunderstorm:
        return 'ic_widget_thunder';
      case WeatherCondition.night:
        return 'ic_widget_moon';
      default:
        return 'ic_widget_cloudy';
    }
  }

  /// Requests the OS to pin the widget to the user's home screen.
  /// Supported on Android 8.0+ (API 26+).
  /// Returns [true] if the request was successfully initiated.
  static Future<bool> requestPinWidget() async {
    try {
      // Pre-check: does this launcher support pinning at all?
      final isSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isSupported != true) {
        return false;
      }

      // Force a fresh data update to SharedPreferences before pinning,
      // so the widget doesn't start blank if the OS skips the initial onUpdate.
      if (_latestSnapshot != null && _latestUnit != null) {
        await updateWidget(_latestSnapshot!, _latestUnit!);
      }

      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: 'com.auroclime.app.AuroclimeWidgetProvider',
      );

      // On some custom Android launchers (like MIUI), pinning a widget
      // programmatically bypasses the traditional initial `onUpdate` broadcast.
      // To ensure the widget doesn't get stuck on the "Loading..." XML layout,
      // we continuously push refresh intents in the background for 15 seconds,
      // catching the widget exactly when it successfully lands on the home screen.
      Future(() async {
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(seconds: 3));
          try {
            await HomeWidget.updateWidget(androidName: _androidWidgetName);
          } catch (_) {}
        }
      });

      return true;
    } catch (e) {
      print('⚠️ Failed to request widget pin: $e');
      return false;
    }
  }
}
