import 'package:shared_preferences/shared_preferences.dart';

/// Tracks weather streaks (sunny days, rain-free days, etc.)
class WeatherStreakService {
  static const String _lastConditionKey = 'streak_last_condition';
  static const String _streakCountKey = 'streak_count';
  static const String _streakTypeKey = 'streak_type';
  static const String _lastUpdateKey = 'streak_last_update';

  /// Update streak based on current weather code
  Future<WeatherStreak> updateStreak(int weatherCode) async {
    final prefs = await SharedPreferences.getInstance();
    
    final lastUpdate = prefs.getString(_lastUpdateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    // Already updated today
    if (lastUpdate == today) {
      return getCurrentStreak();
    }
    
    final currentType = _getStreakType(weatherCode);
    final savedType = prefs.getString(_streakTypeKey);
    final currentCount = prefs.getInt(_streakCountKey) ?? 0;
    
    int newCount;
    String newType;
    
    if (savedType == currentType && currentType.isNotEmpty) {
      // Continue streak
      newCount = currentCount + 1;
      newType = currentType;
    } else {
      // New streak
      newCount = 1;
      newType = currentType;
    }
    
    await prefs.setString(_streakTypeKey, newType);
    await prefs.setInt(_streakCountKey, newCount);
    await prefs.setString(_lastUpdateKey, today);
    await prefs.setInt(_lastConditionKey, weatherCode);
    
    return WeatherStreak(
      type: newType,
      count: newCount,
      emoji: _getStreakEmoji(newType),
      message: _getStreakMessage(newType, newCount),
    );
  }
  
  /// Get current streak without updating
  Future<WeatherStreak> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    
    final type = prefs.getString(_streakTypeKey) ?? '';
    final count = prefs.getInt(_streakCountKey) ?? 0;
    
    if (type.isEmpty || count == 0) {
      return WeatherStreak.empty();
    }
    
    return WeatherStreak(
      type: type,
      count: count,
      emoji: _getStreakEmoji(type),
      message: _getStreakMessage(type, count),
    );
  }
  
  String _getStreakType(int weatherCode) {
    // Sunny/Clear: 0, 1
    if (weatherCode <= 1) return 'sunny';
    
    // Cloudy but dry: 2, 3
    if (weatherCode <= 3) return 'dry';
    
    // Rain: 51-67, 80-82
    if ((weatherCode >= 51 && weatherCode <= 67) || 
        (weatherCode >= 80 && weatherCode <= 82)) return 'rainy';
    
    // Snow: 71-77, 85-86
    if ((weatherCode >= 71 && weatherCode <= 77) || 
        (weatherCode >= 85 && weatherCode <= 86)) return 'snowy';
    
    // Storm: 95-99
    if (weatherCode >= 95) return 'stormy';
    
    // Default - dry weather
    return 'dry';
  }
  
  String _getStreakEmoji(String type) {
    switch (type) {
      case 'sunny': return '☀️';
      case 'dry': return '🌤️';
      case 'rainy': return '🌧️';
      case 'snowy': return '❄️';
      case 'stormy': return '⛈️';
      default: return '🌡️';
    }
  }
  
  String _getStreakMessage(String type, int count) {
    if (count < 2) return '';
    
    switch (type) {
      case 'sunny':
        if (count >= 7) return '$count sunny days! ☀️ Amazing streak!';
        if (count >= 3) return '$count sunny days in a row!';
        return '$count sunny days';
      case 'dry':
        if (count >= 7) return '$count rain-free days!';
        if (count >= 3) return '$count days without rain';
        return 'No rain for $count days';
      case 'rainy':
        if (count >= 5) return '$count rainy days... hang in there!';
        return '$count rainy days';
      case 'snowy':
        return '$count snowy days! ❄️';
      case 'stormy':
        return 'Stay safe - $count stormy days';
      default:
        return '$count day streak';
    }
  }
}

class WeatherStreak {
  final String type;
  final int count;
  final String emoji;
  final String message;
  
  WeatherStreak({
    required this.type,
    required this.count,
    required this.emoji,
    required this.message,
  });
  
  factory WeatherStreak.empty() => WeatherStreak(
    type: '',
    count: 0,
    emoji: '',
    message: '',
  );
  
  bool get hasStreak => count >= 2 && message.isNotEmpty;
}
