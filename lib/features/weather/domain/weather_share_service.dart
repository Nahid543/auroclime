import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Service for sharing weather as image
class WeatherShareService {
  /// Share weather data as text
  static Future<void> shareAsText({
    required String locationName,
    required int temperature,
    required String condition,
    required int high,
    required int low,
    String? tip,
  }) async {
    final text = '''
🌡️ Weather in $locationName

$temperature° - $condition
↑ High: $high° | ↓ Low: $low°
${tip != null ? '\n💡 $tip' : ''}

Shared via Auroclime
''';
    
    await Share.share(text, subject: 'Weather in $locationName');
  }
  
  /// Capture widget as image and share
  static Future<void> shareAsImage(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary = 
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/auroclime_weather.png');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Current weather - Shared via Auroclime',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }
}

/// Shareable weather card widget
class ShareableWeatherCard extends StatelessWidget {
  final GlobalKey cardKey;
  final String locationName;
  final int temperature;
  final String condition;
  final int high;
  final int low;
  final String? tip;
  final IconData weatherIcon;

  const ShareableWeatherCard({
    super.key,
    required this.cardKey,
    required this.locationName,
    required this.temperature,
    required this.condition,
    required this.high,
    required this.low,
    this.tip,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 4),
                Text(
                  locationName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Weather icon and temp
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  weatherIcon,
                  color: const Color(0xFF38BDF8),
                  size: 48,
                ),
                const SizedBox(width: 12),
                Text(
                  '$temperature°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Condition
            Text(
              condition,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // High/Low
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTempPill('↑ $high°', const Color(0xFFF97316)),
                const SizedBox(width: 12),
                _buildTempPill('↓ $low°', const Color(0xFF3B82F6)),
              ],
            ),
            
            if (tip != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Branding
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
              ).createShader(bounds),
              child: const Text(
                'Auroclime',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTempPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
