import 'package:flutter/material.dart';
import '../../domain/weather_streak_service.dart';

class WeatherStreakCard extends StatelessWidget {
  final WeatherStreak streak;

  const WeatherStreakCard({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    if (!streak.hasStreak) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStreakColor(streak.type).withOpacity(0.15),
            _getStreakColor(streak.type).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStreakColor(streak.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Streak icon with fire effect
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStreakColor(streak.type).withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                streak.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${streak.count}',
                      style: TextStyle(
                        color: _getStreakColor(streak.type),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Day Streak',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (streak.count >= 5) ...[
                      const SizedBox(width: 6),
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  streak.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStreakColor(String type) {
    switch (type) {
      case 'sunny': return const Color(0xFFFBBF24); // Yellow
      case 'dry': return const Color(0xFF38BDF8); // Sky blue
      case 'rainy': return const Color(0xFF60A5FA); // Blue
      case 'snowy': return const Color(0xFFA5B4FC); // Light purple
      case 'stormy': return const Color(0xFFF87171); // Red
      default: return const Color(0xFF38BDF8);
    }
  }
}
