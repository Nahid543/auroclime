import 'package:flutter/material.dart';
import '../../domain/weather_service.dart';
import '../../domain/settings_service.dart';

class DailyForecastList extends StatelessWidget {
  final List<UIDailyWeather> items;
  final TemperatureUnit temperatureUnit;

  const DailyForecastList({
    super.key,
    required this.items,
    this.temperatureUnit = TemperatureUnit.celsius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white12, width: 0.7),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _DailyRow(
              item: items[i],
              index: i,
              temperatureUnit: temperatureUnit,
            ),
            if (i != items.length - 1)
              Divider(
                height: 1,
                color: Colors.white.withOpacity(0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final UIDailyWeather item;
  final int index;
  final TemperatureUnit temperatureUnit;

  const _DailyRow({
    required this.item,
    required this.index,
    required this.temperatureUnit,
  });

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final displayHigh = temperatureUnit == TemperatureUnit.fahrenheit
        ? settingsService.celsiusToFahrenheit(item.high)
        : item.high;

    final displayLow = temperatureUnit == TemperatureUnit.fahrenheit
        ? settingsService.celsiusToFahrenheit(item.low)
        : item.low;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: index == 0
                    ? const [Color(0xFF22D3EE), Color(0xFF6366F1)]
                    : [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.02),
                      ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            _iconForCondition(item.condition),
            size: 22,
            color: Colors.white70,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dayLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isSmallScreen ? 14 : 15,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$displayHigh° / $displayLow°',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: isSmallScreen ? 14 : 15,
                ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForCondition(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.clear:
      return Icons.wb_sunny_rounded;
    case WeatherCondition.partlyCloudy:
      return Icons.cloud_queue_rounded;
    case WeatherCondition.cloudy:
      return Icons.cloud_rounded;
    case WeatherCondition.rain:
      return Icons.grain_rounded;
    case WeatherCondition.thunderstorm:
      return Icons.thunderstorm_rounded;
    case WeatherCondition.night:
      return Icons.nightlight_round;
  }
}
