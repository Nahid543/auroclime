import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/rainviewer_api.dart';

/// Full-screen weather radar map with animated playback of past precipitation.
class RadarScreen extends StatefulWidget {
  const RadarScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  final double latitude;
  final double longitude;
  final String locationName;

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with TickerProviderStateMixin {
  final _rainViewerApi = RainViewerApi();
  final _mapController = MapController();

  RadarMapData? _radarData;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentFrameIndex = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;

  double _radarOpacity = 0.6;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchRadarData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _pulseController.dispose();
    _rainViewerApi.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchRadarData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await _rainViewerApi.fetchRadarFrames();

      if (mounted) {
        setState(() {
          _radarData = data;
          _isLoading = false;
          // Start at the latest frame.
          _currentFrameIndex =
              data.pastFrames.isNotEmpty ? data.pastFrames.length - 1 : 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load radar data. Check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlayback() {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_radarData == null || _radarData!.pastFrames.isEmpty) return;

    setState(() => _isPlaying = true);
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) {
        if (!mounted || _radarData == null) return;
        setState(() {
          _currentFrameIndex =
              (_currentFrameIndex + 1) % _radarData!.pastFrames.length;
        });
      },
    );
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onFrameSelected(int index) {
    HapticFeedback.selectionClick();
    _stopPlayback();
    setState(() => _currentFrameIndex = index);
  }

  void _recenterMap() {
    HapticFeedback.lightImpact();
    _mapController.move(
      LatLng(widget.latitude, widget.longitude),
      6.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildRadarMap(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF38BDF8).withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF38BDF8).withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar_rounded,
              color: const Color(0xFF38BDF8),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Weather Radar',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: _recenterMap,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF38BDF8),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading radar data...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDC2626).withOpacity(0.15),
                    const Color(0xFFF97316).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFF97316),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchRadarData,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarMap() {
    final radarData = _radarData;
    if (radarData == null || radarData.pastFrames.isEmpty) {
      return _buildErrorState();
    }

    final currentFrame = radarData.pastFrames[_currentFrameIndex];

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.latitude, widget.longitude),
            initialZoom: 6.0,
            minZoom: 3.0,
            maxZoom: 7.0,
            backgroundColor: const Color(0xFF020617),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Dark base map (CartoDB Dark Matter)
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.auroclime.app',
              maxZoom: 19,
              tileBuilder: _darkTileBuilder,
            ),

            // Radar overlay
            Opacity(
              opacity: _radarOpacity,
              child: TileLayer(
                urlTemplate: currentFrame.tileUrlTemplate(size: 256),
                userAgentPackageName: 'com.auroclime.app',
                maxZoom: 7,
                tileBuilder: _radarTileBuilder,
              ),
            ),

            // User location marker
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(widget.latitude, widget.longitude),
                  width: 48,
                  height: 48,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse ring
                          Container(
                            width: 48 * _pulseAnimation.value,
                            height: 48 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF38BDF8)
                                  .withOpacity(0.15 * (1 - _pulseAnimation.value)),
                            ),
                          ),
                          // Inner dot
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF38BDF8),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8)
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        // Bottom control panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildControlPanel(radarData),
        ),

        // Precipitation legend
        Positioned(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildLegend(),
              const SizedBox(height: 10),
              _buildNoPrecipIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _darkTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.3, 0, 0, 0, 0,
        0, 0.3, 0, 0, 0,
        0, 0, 0.35, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  Widget _radarTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return tileWidget;
  }

  Widget _buildControlPanel(RadarMapData radarData) {
    final currentFrame = radarData.pastFrames[_currentFrameIndex];
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 110),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withOpacity(0.0),
            const Color(0xFF0F172A).withOpacity(0.85),
            const Color(0xFF0F172A).withOpacity(0.95),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location and time info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.locationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isPlaying
                                ? const Color(0xFF10B981)
                                : const Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentFrame.relativeTime,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Opacity control
              Row(
                children: [
                  Icon(
                    Icons.opacity_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                  SizedBox(
                    width: 80,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF38BDF8),
                        inactiveTrackColor:
                            Colors.white.withOpacity(0.15),
                        thumbColor: const Color(0xFF38BDF8),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        trackHeight: 3,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: _radarOpacity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() => _radarOpacity = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timeline strip
          SizedBox(
            height: 44,
            child: Row(
              children: [
                // Play/pause button
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF38BDF8).withOpacity(0.2),
                          const Color(0xFF0EA5E9).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFF38BDF8),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Frame indicators
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: radarData.pastFrames.length,
                    itemBuilder: (context, index) {
                      final isActive = index == _currentFrameIndex;

                      return GestureDetector(
                        onTap: () => _onFrameSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 36 : 10,
                          height: 6,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 19,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF38BDF8)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    // These colors match the RainViewer Universal Blue color scheme at key dBZ values.
    const legendStops = <_LegendStop>[
      _LegendStop(Color(0xFF88DDEE), '15 dBZ', '~0.5 mm/hr'),  // Light drizzle
      _LegendStop(Color(0xFF00A3E0), '20 dBZ', '~1 mm/hr'),    // Light rain
      _LegendStop(Color(0xFF6E0DC6), '20+',    ''),             // Transition
      _LegendStop(Color(0xFFFFEE00), '35 dBZ', '~4 mm/hr'),    // Moderate rain
      _LegendStop(Color(0xFFFF4400), '45 dBZ', '~16 mm/hr'),   // Heavy rain
      _LegendStop(Color(0xFFC10000), '50 dBZ', '~32 mm/hr'),   // Very heavy
      _LegendStop(Color(0xFFFF77FF), '60 dBZ', '~50+ mm/hr'),  // Extreme / hail
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF38BDF8).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PRECIPITATION',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          // Gradient bar + labels
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient bar
              Container(
                width: 10,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: legendStops.map((s) => s.color).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Labels along the bar
              SizedBox(
                height: 110,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGradientLabel('Light'),
                    _buildGradientLabel('Moderate'),
                    _buildGradientLabel('Heavy'),
                    _buildGradientLabel('Extreme'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Rainfall rate range
          Text(
            '0.5 – 50+ mm/hr',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildNoPrecipIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF10B981),
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            'No precipitation nearby',
            style: TextStyle(
              color: const Color(0xFF10B981).withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple data holder for a gradient-legend color stop.
class _LegendStop {
  const _LegendStop(this.color, this.dbzLabel, this.rateLabel);
  final Color color;
  final String dbzLabel;
  final String rateLabel;
}
