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
        return '🚨 Severe thunderstorm with hail! Stay indoors, away from windows, and secure outdoor items.';
      }
      if (weatherCode == 96) {
        return '⚠️ Thunderstorm with scattered hail possible. Move indoors and stay safe until it passes.';
      }
      return '⛈️ Thunderstorms in the vicinity. Avoid open areas and consider unplugging sensitive electronics.';
    }

    if ((weatherCode >= 56 && weatherCode <= 57) ||
        (weatherCode >= 66 && weatherCode <= 67)) {
      return '🧊 Freezing precipitation likely! Roads and sidewalks will be extremely slippery. Travel only if necessary.';
    }

    if (weatherCode == 75 || weatherCode == 77 || weatherCode == 85 || weatherCode == 86) {
      return '❄️ Heavy snowfall expected. Bundle up, drive slowly, and allow extra time for travel.';
    }

    if (apparent <= -20) {
      return '🥶 Dangerously cold outside! Risk of frostbite is high. Limit exposure and cover all skin.';
    }

    if (temperature >= 38 || apparent >= 40) {
      return '🔥 Extreme heat warning! Stay in air conditioning, hydrate constantly, and avoid midday sun.';
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
    final hour = DateTime.now().hour;
    final timeOfDay = _getTimeOfDay(hour);
    
    // HIGH PRIORITY: Rain/Weather conditions
    if (rainProbability > 60) {
      return timeOfDay == 'morning'
          ? '☔ High chance of heavy rain today! Don\'t forget your umbrella and plan for slower traffic.'
          : '☔ Heavy rain is likely. Perfect time to stay indoors with a hot beverage.';
    }
    if (rainProbability > 30) {
      return timeOfDay == 'morning'
          ? '🌧️ Rain is quite possible today! Keep a compact umbrella handy just in case.'
          : '🌧️ There\'s a chance of scattered showers. Better to be prepared if you\'re heading out.';
    }

    // EXTREME CONDITIONS
    if (temperature > 32 && humidity > 70) {
      return '🥵 It\'s hot and very humid out there! Take it easy, seek shade, and keep a water bottle nearby.';
    }

    if (temperature > 35) {
      return timeOfDay == 'afternoon'
          ? '☀️ The sun is blazing! Stay indoors during peak hours to avoid heat exhaustion.'
          : '☀️ It\'s going to be a scorcher! Wear light, breathable clothing and hydrate frequently.';
    }

    if (temperature > 30) {
      return timeOfDay == 'morning'
          ? '🕶️ A hot day is brewing! Apply sunscreen generously before stepping outside.'
          : '🕶️ It\'s quite warm! Take frequent breaks in the shade if you\'re active outdoors.';
    }

    if (temperature < 5) {
      return '🧣 Bitterly cold! Opt for thermal layers, a thick coat, and a warm hat if venturing out.';
    }

    if (temperature < 10) {
      return timeOfDay == 'morning'
          ? '🧤 Chilly start to the day! A warm jacket and a hot coffee are highly recommended.'
          : '🧤 It\'s quite brisk outside! Make sure you\'re bundled up to stay comfortable.';
    }

    if (temperature < 15) {
      return timeOfDay == 'evening'
          ? '🧥 The temperature is dropping tonight. Bring a light jacket or sweater if going out.'
          : '🧥 Cool and crisp weather! Perfect for a light layer to keep the chill away.';
    }

    // WIND
    if (windSpeed > 25) {
      return '🌬️ Very gusty out there! Keep a firm grip on your belongings and drive carefully.';
    }

    if (windSpeed > 15) {
      return '🍃 It\'s quite breezy! A great day for flying a kite, but maybe hold onto your hat.';
    }

    // HUMIDITY
    if (humidity > 80) {
      return '💧 The air is thick with humidity! It might feel muggier than the actual temperature.';
    }

    // PERFECT WEATHER
    if (temperature >= 20 &&
        temperature <= 28 &&
        humidity < 70 &&
        rainProbability < 20) {
      if (timeOfDay == 'morning') {
        return '✨ the weather is absolutely perfect right now! Get out there and enjoy a beautiful morning walk.';
      } else if (timeOfDay == 'afternoon') {
        return '✨ Gorgeous weather this afternoon! Excellent conditions for an outdoor lunch or a park visit.';
      } else if (timeOfDay == 'evening') {
        return '✨ A beautiful, clear evening awaits! Perfect template for an outdoor dinner or stroll.';
      }
      return '✨ Spectacular weather conditions! It doesn\'t get much better than this.';
    }

    // TIME-SPECIFIC TIPS
    if (timeOfDay == 'morning') {
      if (temperature >= 18 && temperature <= 25) {
        return '🌅 Pleasant morning vibes! The temperature is exactly right for an energizing jog.';
      }
      return '🌅 Good morning! A relatively calm day ahead. Check the hourly forecast if you plan to be out long.';
    }

    if (timeOfDay == 'afternoon') {
      if (temperature >= 22 && temperature <= 30) {
        return '😎 Comfortable afternoon weather! Take a quick 10-minute break outside to soak it in.';
      }
      return '😎 Standard afternoon weather. If you\'re out in the sun, remember your sunglasses!';
    }

    if (timeOfDay == 'evening') {
      if (temperature >= 15 && temperature <= 25) {
        return '🌆 A lovely, mild evening. Ideal conditions to unwind and take a relaxing stroll.';
      }
      return '🌆 The day is winding down! Check tonight\'s forecast before making late plans.';
    }

    if (timeOfDay == 'night') {
      if (temperature < 15) {
        return '🌙 It\'s a cool night. Might be a good idea to keep windows closed and grab an extra blanket.';
      }  
      return '🌙 Peaceful night conditions out there. Sleep well and check tomorrow\'s overview when you wake up!';
    }

    // MILD/MODERATE CONDITIONS
    if (temperature >= 18 && temperature <= 25) {
      return '👍 The weather is pleasantly mild. Whatever you have planned, the atmosphere is on your side!';  
    }

    // DEFAULT
    return '💡 Keep an eye on the hourly forecast for the most accurate and up-to-date weather pacing.';
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
