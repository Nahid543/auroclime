import 'package:flutter/material.dart';
import '../../domain/weather_service.dart';
import '../../domain/settings_service.dart';
import 'animated_weather_icon.dart';

class CurrentWeatherCard extends StatelessWidget {
  final UICurrentWeather current;
  final TemperatureUnit temperatureUnit;
  final WindSpeedUnit windSpeedUnit;

  const CurrentWeatherCard({
    super.key,
    required this.current,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.windSpeedUnit = WindSpeedUnit.kmh,
  });

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final displayTemp = temperatureUnit == TemperatureUnit.fahrenheit
        ? settingsService.celsiusToFahrenheit(current.temperature)
        : current.temperature;

    final displayFeelsLike = temperatureUnit == TemperatureUnit.fahrenheit
        ? settingsService.celsiusToFahrenheit(current.feelsLike)
        : current.feelsLike;

    final tempSymbol = temperatureUnit.symbol;
    final windSpeed = settingsService.formatWindSpeed(current.windKph, windSpeedUnit);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
        border: Border.all(color: Colors.white12, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: displayTemp.toDouble()),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          '${value.round()}°',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 48 : 56,
                              ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.weatherDescription,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: isSmallScreen ? 15 : 18,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Feels like $displayFeelsLike$tempSymbol',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.air_rounded,
                      label: 'Wind $windSpeed',
                    ),
                    _InfoChip(
                      icon: Icons.water_drop_rounded,
                      label: 'Humidity ${current.humidity}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _WeatherIconBig(condition: current.condition),
        ],
      ),
    );
  }
}

class _WeatherIconBig extends StatelessWidget {
  final WeatherCondition condition;

  const _WeatherIconBig({required this.condition});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(
                          const Color(0xFF0F172A),
                          const Color(0xFF38BDF8),
                          value,
                        )!,
                        const Color(0xFF0F172A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4 * value),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedWeatherIcon(condition: condition),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}
