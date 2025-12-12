import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/weather_service.dart';
import '../../domain/settings_service.dart';

class HourlyForecastStrip extends StatelessWidget {
  final List<UIHourlyWeather> items;
  final TemperatureUnit temperatureUnit;

  const HourlyForecastStrip({
    super.key,
    required this.items,
    this.temperatureUnit = TemperatureUnit.celsius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _HourlyCard(
            item: items[index],
            index: index,
            temperatureUnit: temperatureUnit,
          );
        },
      ),
    );
  }
}

class _HourlyCard extends StatefulWidget {
  final UIHourlyWeather item;
  final int index;
  final TemperatureUnit temperatureUnit;

  const _HourlyCard({
    required this.item,
    required this.index,
    required this.temperatureUnit,
  });

  @override
  State<_HourlyCard> createState() => _HourlyCardState();
}

class _HourlyCardState extends State<_HourlyCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    final displayTemp = widget.temperatureUnit == TemperatureUnit.fahrenheit
        ? settingsService.celsiusToFahrenheit(widget.item.temperature)
        : widget.item.temperature;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _animController,
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: Colors.white.withOpacity(widget.index == 0 ? 0.28 : 0.1),
                  width: widget.index == 0 ? 1.1 : 0.7,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.item.timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    _iconForCondition(widget.item.condition),
                    size: 26,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$displayTemp°',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.item.rainChance}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.lightBlueAccent.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
