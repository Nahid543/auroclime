import 'package:flutter/material.dart';
import '../../domain/weather_service.dart';

class AirQualityCard extends StatelessWidget {
  final UIAirQuality airQuality;

  const AirQualityCard({
    super.key,
    required this.airQuality,
  });

  Color _getAqiColor() {
    switch (airQuality.level) {
      case AQILevel.good:
        return const Color(0xFF10B981);
      case AQILevel.moderate:
        return const Color(0xFFFBBF24);
      case AQILevel.unhealthySensitive:
        return const Color(0xFFF97316);
      case AQILevel.unhealthy:
        return const Color(0xFFEF4444);
      case AQILevel.veryUnhealthy:
        return const Color(0xFF9333EA);
      case AQILevel.hazardous:
        return const Color(0xFF7F1D1D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aqiColor = _getAqiColor();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1D4ED8).withOpacity(0.3),
            const Color(0xFF22D3EE).withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          color: const Color(0xFF020617),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aqiColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.air,
                color: aqiColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Air Quality',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: aqiColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${airQuality.aqi}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    airQuality.category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: aqiColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    airQuality.advice,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Primary: ${airQuality.primaryPollutant}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
