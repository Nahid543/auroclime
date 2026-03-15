import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/saved_locations_service.dart';
import '../../domain/location_service.dart';
import 'home_screen.dart';
import 'radar_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../../domain/search_service.dart';

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _savedLocationsService = SavedLocationsService();
  final _locationService = LocationService();

  // We maintain coordinates for the Radar screen
  double? _currentLat;
  double? _currentLng;
  String _currentName = 'Your Location';

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    final locations = await _savedLocationsService.getSavedLocations();
    if (locations.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currentLat = locations.first.latitude;
          _currentLng = locations.first.longitude;
          _currentName = locations.first.name;
        });
      }
    } else {
      // Try fetching GPS if no saved locations
      try {
        final loc = await _locationService.getCurrentLocation();
        if (loc.latitude != null && loc.longitude != null && mounted) {
          setState(() {
            _currentLat = loc.latitude;
            _currentLng = loc.longitude;
          });
        }
      } catch (e) {
        // Fallback to default (e.g. Dhaka)
        if (mounted) {
          setState(() {
            _currentLat = 23.8103;
            _currentLng = 90.4125;
            _currentName = 'Dhaka';
          });
        }
      }
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4 tab screens
    final screens = [
      HomeScreen(key: homeScreenKey),
      SearchScreen(
        onLocationSelected: (loc) {
          _onTabTapped(0);
          homeScreenKey.currentState?.scrollToSavedLocation(loc);
        },
      ),
      _currentLat != null && _currentLng != null
          ? RadarScreen(
              latitude: _currentLat!,
              longitude: _currentLng!,
              locationName: _currentName,
            )
          : RadarScreen(
              latitude: 23.8103, // Fallback
              longitude: 90.4125,
              locationName: 'Dhaka',
            ),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          
          // Floating Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.cloud_outlined, Icons.cloud, 'Weather'),
                      _buildNavItem(1, Icons.search_outlined, Icons.search, 'Search'),
                      _buildNavItem(2, Icons.radar_outlined, Icons.radar, 'Radar'),
                      _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Settings'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String tooltip) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? iconFilled : iconOutlined,
                color: isSelected ? const Color(0xFF38BDF8) : Colors.white54,
                size: 26,
              ),
              const SizedBox(height: 2),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
