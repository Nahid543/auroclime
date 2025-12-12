import 'package:flutter/material.dart';
import '../../domain/weather_service.dart';

class AnimatedWeatherIcon extends StatefulWidget {
  final WeatherCondition condition;
  final double size;

  const AnimatedWeatherIcon({
    super.key,
    required this.condition,
    this.size = 52,
  });

  @override
  State<AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<AnimatedWeatherIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Icon(
              _iconForCondition(widget.condition, isDay: true),
              color: Colors.white,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

IconData _iconForCondition(WeatherCondition condition, {bool isDay = false}) {
  switch (condition) {
    case WeatherCondition.clear:
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    case WeatherCondition.partlyCloudy:
      return isDay ? Icons.cloud_queue_rounded : Icons.cloudy_snowing;
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
