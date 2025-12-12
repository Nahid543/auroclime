// lib/features/weather/domain/auroclime_tips.dart

import 'dart:math';

import '../data/weather_models.dart';

class AuroclimeTipEngine {
  static final Random _random = Random();

  /// Main entry: call from WeatherService and use result.message as snapshot.tip.
  static TipResult fromWeather({
    required CurrentConditions current,
    int? humidityOverride,
    int? rainProbabilityOverride,
  }) {
    final temperature = current.temperature.round();
    final humidity = humidityOverride ?? 65;
    final windSpeed = current.windSpeed;
    final isDay = current.isDay;
    final rainProbability =
        rainProbabilityOverride ?? _estimateRainProbabilityFromCode(current.weatherCode);

    final safetyTip = _getSafetyTip(
      weatherCode: current.weatherCode,
      temperature: current.temperature,
      apparent: current.temperature,
    );
    if (safetyTip != null) {
      return TipResult(
        message: safetyTip,
        comfortLevel: ComfortLevel.uncomfortable,
      );
    }

    final tip = _selectTip(
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      rainProbability: rainProbability,
      isDay: isDay,
    );

    return TipResult(
      message: tip,
      comfortLevel: _calculateComfortLevel(temperature, humidity),
    );
  }

  static TipResult generateTip({
    required int temperature,
    required int humidity,
    required double windSpeed,
    required int rainProbability,
    required bool isDay,
  }) {
    final comfortLevel = _calculateComfortLevel(temperature, humidity);
    final tip = _selectTip(
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      rainProbability: rainProbability,
      isDay: isDay,
    );

    return TipResult(
      message: tip,
      comfortLevel: comfortLevel,
    );
  }

  static String? _getSafetyTip({
    required int weatherCode,
    required double temperature,
    required double apparent,
  }) {
    if (weatherCode >= 95) {
      if (weatherCode == 99) {
        return 'Severe thunderstorm with hail. Stay indoors and avoid windows.';
      }
      if (weatherCode == 96) {
        return 'Thunderstorm with hail possible. Move indoors and secure loose items.';
      }
      return 'Thunderstorm nearby. Avoid open areas and unplug sensitive electronics.';
    }

    if ((weatherCode >= 56 && weatherCode <= 57) ||
        (weatherCode >= 66 && weatherCode <= 67)) {
      return 'Freezing precipitation possible. Roads and sidewalks may be icy—travel with caution.';
    }

    if (weatherCode == 75 || weatherCode == 77 || weatherCode == 85 || weatherCode == 86) {
      return 'Heavy snow or blowing snow. Allow extra travel time and dress warmly.';
    }

    if (apparent <= -20) {
      return 'Extreme cold. Limit time outside and cover exposed skin.';
    }

    if (temperature >= 38) {
      return 'Extreme heat. Stay hydrated, avoid midday sun, and check on vulnerable people.';
    }

    return null;
  }

  static int _estimateRainProbabilityFromCode(int weatherCode) {
    if (weatherCode >= 51 && weatherCode <= 99) {
      return 70 + _random.nextInt(31);
    }
    if (weatherCode == 3) {
      return 20 + _random.nextInt(21);
    }
    return 10 + _random.nextInt(21);
  }

  static String _selectTip({
    required int temperature,
    required int humidity,
    required double windSpeed,
    required int rainProbability,
    required bool isDay,
  }) {
    // Get current hour for time-based tips
    final hour = DateTime.now().hour;
    final timeOfDay = _getTimeOfDay(hour);
    
    // HIGH PRIORITY: Rain/Weather conditions
    if (rainProbability > 60) {
      return timeOfDay == 'morning'
          ? 'Heavy rain expected today. Keep an umbrella and plan for delays.'
          : 'Heavy rain likely. Stay indoors or wear waterproof gear.';
    }
    if (rainProbability > 30) {
      return timeOfDay == 'morning'
          ? 'Rain possible today. Carry an umbrella just in case.'
          : 'Chance of rain. Keep an umbrella handy.';
    }

    // EXTREME CONDITIONS
    if (temperature > 32 && humidity > 70) {
      return 'Hot and humid—stay hydrated, seek air conditioning, and avoid strenuous activity.';
    }

    if (temperature > 35) {
      return timeOfDay == 'afternoon'
          ? 'Extreme heat! Stay indoors during peak hours. Drink plenty of water.'
          : 'Extreme heat today. Avoid midday sun and stay well-hydrated.';
    }

    if (temperature > 30) {
      return timeOfDay == 'morning'
          ? 'Hot day ahead! Wear light clothing, apply sunscreen, and stay cool.'
          : 'Warm weather. Take breaks in shade and drink water frequently.';
    }

    if (temperature < 5) {
      return 'Very cold! Dress in layers, cover extremities, and limit outdoor time.';
    }

    if (temperature < 10) {
      return timeOfDay == 'morning'
          ? 'Cold morning. Wear warm layers and don\'t forget gloves and a scarf.'
          : 'Cold outside. Bundle up with warm clothing before heading out.';
    }

    if (temperature < 15) {
      return timeOfDay == 'evening'
          ? 'Chilly evening ahead. Bring a jacket if going out tonight.'
          : 'Cool conditions. Layer up and keep a jacket nearby.';
    }

    // WIND
    if (windSpeed > 25) {
      return 'Strong winds today. Secure loose items and be cautious while driving.';
    }

    if (windSpeed > 15) {
      return 'Breezy conditions. Hold onto your hat and secure outdoor furniture.';
    }

    // HUMIDITY
    if (humidity > 80) {
      return 'High humidity—you\'ll feel warmer than the temperature suggests. Stay cool!';
    }

    // PERFECT WEATHER
    if (temperature >= 20 &&
        temperature <= 28 &&
        humidity < 70 &&
        rainProbability < 20) {
      if (timeOfDay == 'morning') {
        return 'Perfect weather today! Great for outdoor exercise or a morning walk.';
      } else if (timeOfDay == 'afternoon') {
        return 'Beautiful afternoon! Ideal for outdoor activities or enjoying nature.';
      } else if (timeOfDay == 'evening') {
        return 'Lovely evening ahead. Perfect for a relaxing walk or outdoor dinner.';
      }
      return 'Excellent weather conditions. Perfect day to be outside!';
    }

    // TIME-SPECIFIC TIPS
    if (timeOfDay == 'morning') {
      if (temperature >= 18 && temperature <= 25) {
        return 'Pleasant morning! Perfect temperature for a energizing walk or jog.';
      }
      return 'Good morning! Check hourly forecast to plan your day ahead.';
    }

    if (timeOfDay == 'afternoon') {
      if (temperature >= 22 && temperature <= 30) {
        return 'Nice afternoon weather. Great time to run errands or take a break outside.';
      }
      return 'Check UV index before spending extended time outdoors this afternoon.';
    }

    if (timeOfDay == 'evening') {
      if (temperature >= 15 && temperature <= 25) {
        return 'Comfortable evening temperature. Perfect for outdoor activities after work.';
      }
      return 'Evening is approaching. Check tonight\'s forecast and plan accordingly.';
    }

    if (timeOfDay == 'night') {
      if (temperature < 15) {
        return 'Cool night ahead. Keep windows closed and use extra blankets if needed.';
      }  
      return 'Pleasant night conditions. Review tomorrow\'s forecast to plan ahead.';
    }

    // MILD/MODERATE CONDITIONS
    if (temperature >= 18 && temperature <= 25) {
      return 'Mild and comfortable. Great conditions for any outdoor plans you have!';  
    }

    // DEFAULT
    return 'Stay updated with Auroclime\'s hourly forecasts for the most accurate weather info.';
  }

  static String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  static ComfortLevel _calculateComfortLevel(int temperature, int humidity) {
    final heatIndex = temperature + humidity / 10;

    if (heatIndex > 40) return ComfortLevel.veryUncomfortable;
    if (heatIndex > 35) return ComfortLevel.uncomfortable;
    if (heatIndex > 30) return ComfortLevel.moderate;
    if (heatIndex > 20) return ComfortLevel.comfortable;
    if (heatIndex > 15) return ComfortLevel.moderate;
    return ComfortLevel.uncomfortable;
  }
}

class TipResult {
  final String message;
  final ComfortLevel comfortLevel;

  const TipResult({
    required this.message,
    required this.comfortLevel,
  });
}

enum ComfortLevel {
  comfortable,
  moderate,
  uncomfortable,
  veryUncomfortable;

  String get label {
    switch (this) {
      case ComfortLevel.comfortable:
        return 'Comfortable';
      case ComfortLevel.moderate:
        return 'Moderate';
      case ComfortLevel.uncomfortable:
        return 'Uncomfortable';
      case ComfortLevel.veryUncomfortable:
        return 'Very uncomfortable';
    }
  }

  String get emoji {
    switch (this) {
      case ComfortLevel.comfortable:
        return '😊';
      case ComfortLevel.moderate:
        return '😐';
      case ComfortLevel.uncomfortable:
        return '😰';
      case ComfortLevel.veryUncomfortable:
        return '🥵';
    }
  }
}
