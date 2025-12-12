import 'package:flutter/material.dart';
import 'dart:math' as math;

/// UV Index display levels
enum UVLevel {
  low,
  moderate,
  high,
  veryHigh,
  extreme;

  static UVLevel fromIndex(double uvIndex) {
    if (uvIndex < 3) return UVLevel.low;
    if (uvIndex < 6) return UVLevel.moderate;
    if (uvIndex < 8) return UVLevel.high;
    if (uvIndex < 11) return UVLevel.veryHigh;
    return UVLevel.extreme;
  }

  String get label {
    switch (this) {
      case UVLevel.low:
        return 'Low';
      case UVLevel.moderate:
        return 'Moderate';
      case UVLevel.high:
        return 'High';
      case UVLevel.veryHigh:
        return 'Very High';
      case UVLevel.extreme:
        return 'Extreme';
    }
  }

  Color get color {
    switch (this) {
      case UVLevel.low:
        return const Color(0xFF4CAF50); // Green
      case UVLevel.moderate:
        return const Color(0xFFFFC107); // Yellow/Amber
      case UVLevel.high:
        return const Color(0xFFFF9800); // Orange
      case UVLevel.veryHigh:
        return const Color(0xFFF44336); // Red
      case UVLevel.extreme:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  String get recommendation {
    switch (this) {
      case UVLevel.low:
        return 'No protection required. Safe to be outside.';
      case UVLevel.moderate:
        return 'Wear sunscreen if outside for extended periods.';
      case UVLevel.high:
        return 'Protection essential. Wear sunscreen, hat, and sunglasses.';
      case UVLevel.veryHigh:
        return 'Extra protection needed. Avoid sun during midday hours.';
      case UVLevel.extreme:
        return 'Maximum protection required. Minimize sun exposure.';
    }
  }

  IconData get icon {
    switch (this) {
      case UVLevel.low:
        return Icons.wb_sunny_outlined;
      case UVLevel.moderate:
        return Icons.wb_sunny;
      case UVLevel.high:
      case UVLevel.veryHigh:
        return Icons.warning_amber_rounded;
      case UVLevel.extreme:
        return Icons.dangerous_outlined;
    }
  }
}

/// Modern UV Index card with glassmorphic design
class UVIndexCard extends StatelessWidget {
  final double? uvIndex;

  const UVIndexCard({
    super.key,
    this.uvIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (uvIndex == null) {
      return _buildUnavailableCard(context);
    }

    final level = UVLevel.fromIndex(uvIndex!);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E1E1E).withOpacity(0.7),
                  const Color(0xFF2D2D2D).withOpacity(0.5),
                ]
              : [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // UV Meter - Circular progress indicator
              _buildUVMeter(level, isDark),
              const SizedBox(width: 20),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'UV Index',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: level.color,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level.recommendation,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUVMeter(UVLevel level, bool isDark) {
    final progress = (uvIndex! / 11).clamp(0.0, 1.0);

    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation(
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          // Progress circle with gradient effect
          SizedBox(
            width: 90,
            height: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _GradientCircularProgressPainter(
                    progress: value,
                    color: level.color,
                    strokeWidth: 8,
                  ),
                );
              },
            ),
          ),
          // Center value
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                uvIndex!.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: level.color,
                  height: 1.0,
                ),
              ),
              Text(
                'of 11+',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 40,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UV Index',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for gradient circular progress
class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.3),
          color,
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: (size.width - strokeWidth) / 2,
      ),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
