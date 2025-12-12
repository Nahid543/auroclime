import 'package:flutter/material.dart';
import '../../domain/weather_service.dart';

class AuroclimeTipCard extends StatelessWidget {
  final UITip? tip;

  const AuroclimeTipCard({
    super.key,
    this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Fallback for when tip is null
    final displayTip = tip ??
        UITip(
          message: 'Loading personalized tip...',
          comfortLevel: 'Calculating',
          comfortEmoji: '⏳',
        );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF22D3EE)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withOpacity(0.45),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          color: const Color(0xFF020617),
        ),
        padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFFA855F7)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.tips_and_updates_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Auroclime tip',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 15,
                            ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFF38BDF8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayTip.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.88),
                          height: 1.35,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Comfort level · ${displayTip.comfortLevel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayTip.comfortEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
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
