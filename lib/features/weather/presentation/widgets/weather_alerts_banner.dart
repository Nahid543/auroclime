import 'package:flutter/material.dart';
import '../../domain/weather_service.dart';

class WeatherAlertsBanner extends StatelessWidget {
  final List<UIWeatherAlert> alerts;
  final VoidCallback onTap;

  const WeatherAlertsBanner({
    super.key,
    required this.alerts,
    required this.onTap,
  });

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.minor:
        return const Color(0xFF3B82F6);
      case AlertSeverity.moderate:
        return const Color(0xFFFBBF24);
      case AlertSeverity.severe:
        return const Color(0xFFF97316);
      case AlertSeverity.extreme:
        return const Color(0xFFDC2626);
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.minor:
        return Icons.info_outline;
      case AlertSeverity.moderate:
        return Icons.warning_amber_outlined;
      case AlertSeverity.severe:
        return Icons.warning_outlined;
      case AlertSeverity.extreme:
        return Icons.report_problem;
    }
  }

  AlertSeverity _getHighestSeverity() {
    if (alerts.any((a) => a.severity == AlertSeverity.extreme)) {
      return AlertSeverity.extreme;
    }
    if (alerts.any((a) => a.severity == AlertSeverity.severe)) {
      return AlertSeverity.severe;
    }
    if (alerts.any((a) => a.severity == AlertSeverity.moderate)) {
      return AlertSeverity.moderate;
    }
    return AlertSeverity.minor;
  }

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final highestSeverity = _getHighestSeverity();
    final severityColor = _getSeverityColor(highestSeverity);
    final activeAlerts = alerts.where((a) => a.isActive).toList();
    final alertCount = activeAlerts.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              severityColor.withOpacity(0.2),
              severityColor.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: severityColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              _getSeverityIcon(highestSeverity),
              color: severityColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$alertCount Active Alert${alertCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: severityColor.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
