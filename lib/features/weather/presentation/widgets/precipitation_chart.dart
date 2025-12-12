import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/weather_service.dart';

/// 24-hour precipitation probability bar chart
class PrecipitationChart extends StatelessWidget {
  final List<UIHourlyWeather> hourlyData;

  const PrecipitationChart({
    super.key,
    required this.hourlyData,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyData.isEmpty) {
      return const SizedBox.shrink();
    }

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Precipitation Chance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: _buildChart(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    // Take first 24 hours of data
    final data = hourlyData.take(24).toList();

    final barGroups = data.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.rainChance.toDouble();
      
      // Color intensity based on probability
      Color barColor;
      if (value < 20) {
        barColor = isDark
            ? Colors.blue.shade200.withOpacity(0.3)
            : Colors.blue.shade200;
      } else if (value < 50) {
        barColor = isDark
            ? Colors.blue.shade300.withOpacity(0.5)
            : Colors.blue.shade400;
      } else if (value < 70) {
        barColor = isDark
            ? Colors.blue.shade400.withOpacity(0.7)
            : Colors.blue.shade600;
      } else {
        barColor = isDark
            ? Colors.blue.shade500.withOpacity(0.9)
            : Colors.blue.shade800;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: barColor,
            width: 8,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                barColor.withOpacity(0.7),
                barColor,
              ],
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
          horizontalInterval: 25,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4, // Show every 4 hours
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index].timeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => isDark
                ? const Color(0xFF2D2D2D).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.toInt();
              if (index < 0 || index >= data.length) return null;
              
              return BarTooltipItem(
                '${data[index].timeLabel}\n${rod.toY.round()}%',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeInOut,
    );
  }
}
