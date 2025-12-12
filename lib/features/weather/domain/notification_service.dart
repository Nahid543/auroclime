import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'weather_service.dart';

/// Service for managing weather-related notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _dailySummaryKey = 'daily_summary_enabled';
  static const String _severeAlertsKey = 'severe_alerts_enabled';
  static const String _precipitationKey = 'precipitation_alerts_enabled';
  static const String _notificationTimeKey = 'notification_time';

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // App will open automatically
    // Can add navigation logic here if needed
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ============== DAILY SUMMARY ==============

  /// Enable daily weather summary notification
  Future<void> enableDailySummary(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailySummaryKey, true);
    await prefs.setInt(_notificationTimeKey, hour * 60 + minute);

    await _scheduleDailySummary(hour, minute);
  }

  /// Disable daily weather summary
  Future<void> disableDailySummary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailySummaryKey, false);
    await _notifications.cancel(1); // ID 1 for daily summary
  }

  /// Check if daily summary is enabled
  Future<bool> isDailySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailySummaryKey) ?? false;
  }

  /// Get daily summary notification time
  Future<Map<String, int>> getDailySummaryTime() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_notificationTimeKey) ?? 420; // 7 AM default
    return {
      'hour': minutes ~/ 60,
      'minute': minutes % 60,
    };
  }

  /// Schedule daily weather summary
  Future<void> _scheduleDailySummary(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Daily Weather Summary',
      channelDescription: 'Daily weather forecast notification',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      1, // Notification ID
      'Today\'s Weather',
      'Tap to see your daily forecast',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Show daily summary with weather data
  Future<void> showDailySummaryWithData(UIWeatherSnapshot weather) async {
    if (!await isDailySummaryEnabled()) return;
    if (!await hasPermission()) return;

    final today = weather.daily.isNotEmpty ? weather.daily.first : null;
    if (today == null) return;

    final high = today.high;
    final low = today.low;
    final condition = today.summary; // Use summary instead of condition.displayName

    const androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Daily Weather Summary',
      channelDescription: 'Daily weather forecast notification',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      '${weather.locationName} - $condition',
      'High: $high° • Low: $low°',
      notificationDetails,
    );
  }

  // ============== SEVERE WEATHER ALERTS ==============

  /// Enable severe weather alerts
  Future<void> enableSevereAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_severeAlertsKey, true);
  }

  /// Disable severe weather alerts
  Future<void> disableSevereAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_severeAlertsKey, false);
  }

  /// Check if severe alerts are enabled
  Future<bool> isSevereAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_severeAlertsKey) ?? true; // Enabled by default
  }

  /// Show severe weather alert
  Future<void> showSevereWeatherAlert(UIWeatherAlert alert) async {
    if (!await isSevereAlertsEnabled()) return;
    if (!await hasPermission()) return;

    const androidDetails = AndroidNotificationDetails(
      'severe_alerts',
      'Severe Weather Alerts',
      channelDescription: 'Important weather warnings and alerts',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2, // ID 2 for severe alerts
      '⚠️ ${alert.title}',
      alert.description,
      notificationDetails,
    );
  }

  // ============== PRECIPITATION ALERTS ==============

  /// Enable precipitation alerts
  Future<void> enablePrecipitationAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_precipitationKey, true);
  }

  /// Disable precipitation alerts
  Future<void> disablePrecipitationAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_precipitationKey, false);
  }

  /// Check if precipitation alerts are enabled
  Future<bool> isPrecipitationAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_precipitationKey) ?? false;
  }

  /// Check for upcoming precipitation and alert if needed
  Future<void> checkPrecipitation(List<UIHourlyWeather> hourly) async {
    if (!await isPrecipitationAlertsEnabled()) return;
    if (!await hasPermission()) return;
    if (hourly.isEmpty) return;

    // Check next hour for significant precipitation
    final nextHour = hourly.first;
    if (nextHour.rainChance >= 60) {
      const androidDetails = AndroidNotificationDetails(
        'precipitation',
        'Precipitation Alerts',
        channelDescription: 'Alerts for upcoming rain or snow',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        3, // ID 3 for precipitation
        '🌧️ Rain Expected Soon',
        'There\'s a ${nextHour.rainChance}% chance of precipitation in the next hour',
        notificationDetails,
      );
    }
  }

  // ============== UTILITIES ==============

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    const androidDetails = AndroidNotificationDetails(
      'test',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'Test Notification',
      'Auroclime notifications are working! 🎉',
      notificationDetails,
    );
  }
}
