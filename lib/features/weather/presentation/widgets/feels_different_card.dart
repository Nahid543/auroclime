import 'package:flutter/material.dart';

/// Shows the difference between actual temp and feels-like temp
class FeelsDifferentCard extends StatelessWidget {
  final int actualTemp;
  final int feelsLikeTemp;
  final String unit;

  const FeelsDifferentCard({
    super.key,
    required this.actualTemp,
    required this.feelsLikeTemp,
    this.unit = '°',
  });

  @override
  Widget build(BuildContext context) {
    final difference = feelsLikeTemp - actualTemp;
    
    // Don't show if difference is minimal
    if (difference.abs() < 2) {
      return const SizedBox.shrink();
    }
    
    final isWarmer = difference > 0;
    final diffText = isWarmer ? '+$difference$unit' : '$difference$unit';
    final reason = _getReason(difference, isWarmer);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isWarmer ? const Color(0xFFEF4444) : const Color(0xFF3B82F6))
                .withOpacity(0.12),
            (isWarmer ? const Color(0xFFF97316) : const Color(0xFF06B6D4))
                .withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isWarmer ? const Color(0xFFEF4444) : const Color(0xFF3B82F6))
              .withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          // Temperature comparison
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isWarmer ? Icons.whatshot : Icons.ac_unit,
                      color: isWarmer 
                          ? const Color(0xFFEF4444) 
                          : const Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feels Different',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$actualTemp$unit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white38,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$feelsLikeTemp$unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isWarmer 
                            ? const Color(0xFFEF4444) 
                            : const Color(0xFF3B82F6)
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        diffText,
                        style: TextStyle(
                          color: isWarmer 
                              ? const Color(0xFFEF4444) 
                              : const Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
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
  
  String _getReason(int diff, bool isWarmer) {
    if (diff.abs() >= 5) {
      return isWarmer 
          ? 'High humidity making it feel much warmer'
          : 'Wind chill making it feel much colder';
    }
    return isWarmer 
        ? 'Humidity adding to the warmth'
        : 'Wind making it feel cooler';
  }
}
