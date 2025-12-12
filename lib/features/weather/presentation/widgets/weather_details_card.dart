import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Expandable weather details card showing visibility, pressure, dew point, and sunrise/sunset
class WeatherDetailsCard extends StatefulWidget {
  final double? visibility; // in meters
  final double? pressure; // in hPa
  final double? dewPoint; // in Celsius
  final DateTime? sunrise;
  final DateTime? sunset;

  const WeatherDetailsCard({
    super.key,
    this.visibility,
    this.pressure,
    this.dewPoint,
    this.sunrise,
    this.sunset,
  });

  @override
  State<WeatherDetailsCard> createState() => _WeatherDetailsCardState();
}

class _WeatherDetailsCardState extends State<WeatherDetailsCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            // Header with expand button
            InkWell(
              onTap: _toggleExpand,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'More Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    // Divider
                    Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      height: 1,
                      thickness: 1,
                    ),
                    const SizedBox(height: 20),
                    // Grid of details
                    _buildDetailsGrid(isDark),
                    // Sunrise/Sunset bar if available
                    if (widget.sunrise != null && widget.sunset != null) ...[
                      const SizedBox(height: 20),
                      _buildSunriseSunsetBar(isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                icon: Icons.visibility_outlined,
                label: 'Visibility',
                value: widget.visibility != null
                    ? '${(widget.visibility! / 1000).toStringAsFixed(1)} km'
                    : 'N/A',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                icon: Icons.compress,
                label: 'Pressure',
                value: widget.pressure != null
                    ? '${widget.pressure!.round()} hPa'
                    : 'N/A',
                isDark: isDark,
                trailing: _buildPressureTrend(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                icon: Icons.water_drop_outlined,
                label: 'Dew Point',
                value: widget.dewPoint != null
                    ? '${widget.dewPoint!.round()}°'
                    : 'N/A',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(), // Placeholder for symmetry
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildPressureTrend(bool isDark) {
    // Placeholder for pressure trend - would need historical data
    // For now, return null or you could add random trend for demo
    return null;
  }

  Widget _buildSunriseSunsetBar(bool isDark) {
    final now = DateTime.now();
    final sunrise = widget.sunrise!;
    final sunset = widget.sunset!;

    // Calculate progress through the day
    double progress = 0.0;
    bool isDayTime = false;

    if (now.isAfter(sunrise) && now.isBefore(sunset)) {
      // During day
      final totalDayMinutes = sunset.difference(sunrise).inMinutes;
      final elapsedMinutes = now.difference(sunrise).inMinutes;
      progress = (elapsedMinutes / totalDayMinutes).clamp(0.0, 1.0);
      isDayTime = true;
    } else if (now.isBefore(sunrise)) {
      // Before sunrise
      progress = 0.0;
      isDayTime = false;
    } else {
      // After sunset
      progress = 1.0;
      isDayTime = false;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A237E).withOpacity(0.3),
                  const Color(0xFFFF6F00).withOpacity(0.3),
                ]
              : [
                  const Color(0xFFFFE082),
                  const Color(0xFFFF9800),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.orange.withOpacity(0.2)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSunTime(
                Icons.wb_sunny,
                'Sunrise',
                DateFormat.jm().format(sunrise),
                isDark,
              ),
              _buildSunTime(
                Icons.brightness_3,
                'Sunset',
                DateFormat.jm().format(sunset),
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              // Background bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Progress bar
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.8),
                        Colors.deepOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Sun indicator
              Positioned(
                left: MediaQuery.of(context).size.width *
                    0.85 *
                    progress, // Approximate card width
                child: Transform.translate(
                  offset: const Offset(-8, -6),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isDayTime ? 'Daytime' : 'Nighttime',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunTime(
    IconData icon,
    String label,
    String time,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
