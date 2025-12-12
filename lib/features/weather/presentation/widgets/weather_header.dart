import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/search_service.dart';
import 'location_search_dialog.dart';
import '../screens/settings_screen.dart';

class WeatherHeader extends StatelessWidget {
  final String locationName;
  final String dateText;
  final String lastUpdatedText;
  final VoidCallback onSettingsChanged;
  final Function(double, double, String) onLocationSelected;
  final bool showDeleteButton;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const WeatherHeader({
    super.key,
    required this.locationName,
    required this.dateText,
    required this.lastUpdatedText,
    required this.onSettingsChanged,
    required this.onLocationSelected,
    this.showDeleteButton = false,
    required this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Location name - takes remaining space
            Expanded(
              child: GestureDetector(
                onTap: () => _showLocationSearch(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        locationName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            // Compact icon buttons - no extra spacing
            if (showDeleteButton)
              _buildCompactIconButton(
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showDeleteConfirmation(context);
                },
              ),
            _buildCompactIconButton(
              icon: Icons.settings_outlined,
              color: Colors.white70,
              onTap: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                onSettingsChanged();
              },
            ),
            if (onShare != null)
              _buildCompactIconButton(
                icon: Icons.share_outlined,
                color: const Color(0xFF38BDF8),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onShare!();
                },
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        Text(
          lastUpdatedText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _showLocationSearch(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await showDialog<LocationSearchResult>(
      context: context,
      builder: (context) => LocationSearchDialog(
        searchService: SearchService(),
      ),
    );

    if (result != null) {
      onLocationSelected(result.latitude, result.longitude, result.name);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remove Location?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove $locationName from saved locations?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
