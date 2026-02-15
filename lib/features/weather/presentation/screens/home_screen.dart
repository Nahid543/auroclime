import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/app_lifecycle_service.dart';
import '../../domain/weather_service.dart';
import '../../domain/location_service.dart';
import '../../domain/settings_service.dart';
import '../../domain/saved_locations_service.dart';
import '../../domain/connectivity_service.dart';
import '../widgets/weather_header.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/auroclime_tip_card.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/weather_alerts_banner.dart';
import '../widgets/hourly_forecast_strip.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/footer_status.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/weather_skeleton_loader.dart';
import '../widgets/uv_index_card.dart';
import '../widgets/weather_details_card.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/precipitation_chart.dart';
import '../widgets/weather_streak_card.dart';
import '../widgets/feels_different_card.dart';
import '../../domain/weather_streak_service.dart';
import '../../domain/weather_share_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  final _locationService = LocationService();
  final _settingsService = SettingsService();
  final _savedLocationsService = SavedLocationsService();
  final _connectivityService = ConnectivityService();
  PageController _pageController = PageController();
  final _weatherStreakService = WeatherStreakService();
  WeatherStreak? _currentStreak;

  List<LocationWeatherData> _locations = [];
  int _currentPage = 0;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  WindSpeedUnit _windSpeedUnit = WindSpeedUnit.kmh;
  bool _isLoading = true;
  bool _isRefreshing = false;
  LocationResult? _locationError;
  bool _animateIn = false;
  bool _isOffline = false;
  bool _isHandlingResumeCheck = false;
  bool _pendingSettingsReturn = false;
  bool _shouldDismissBlockingRouteOnResume = false;
  bool _pendingPageViewSync = false;

  @override
  void initState() {
    super.initState();
    AppLifecycleService.state.addListener(_onLifecycleStateChanged);
    _initializeConnectivityMonitoring();
    _initialize();
  }

  @override
  void dispose() {
    AppLifecycleService.state.removeListener(_onLifecycleStateChanged);
    _weatherService.dispose();
    _connectivityService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onLifecycleStateChanged() {
    final state = AppLifecycleService.state.value;
    if (mounted) {
      setState(() {});
    }

    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _schedulePageViewSync({
    required String reason,
    bool allowRecreate = true,
  }) {
    if (_pendingPageViewSync) return;
    _pendingPageViewSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _pendingPageViewSync = false;
      if (!mounted) return;
      await _ensurePageViewState(reason: reason, allowRecreate: allowRecreate);
    });
  }

  int _safeCurrentPageIndex() {
    if (_locations.isEmpty) return 0;
    return _currentPage.clamp(0, _locations.length - 1);
  }

  void _recreatePageController({
    required int initialPage,
    required String reason,
  }) {
    final previous = _pageController;
    _pageController = PageController(initialPage: initialPage);
    previous.dispose();
  }

  Future<void> _ensurePageViewState({
    required String reason,
    bool allowRecreate = false,
  }) async {
    if (!mounted) return;

    if (_locations.isEmpty) {
      if (_currentPage != 0) {
        setState(() => _currentPage = 0);
      }
      return;
    }

    final safeIndex = _safeCurrentPageIndex();
    if (safeIndex != _currentPage && mounted) {
      setState(() => _currentPage = safeIndex);
    }

    if (!_pageController.hasClients) {
      if (allowRecreate) {
        _recreatePageController(
          initialPage: safeIndex,
          reason: 'no_clients/$reason',
        );
        if (mounted) {
          setState(() {});
        }
      }
      return;
    }

    final pageValue = _pageController.page;
    final pageIndex = (pageValue ?? _pageController.initialPage.toDouble())
        .round();
    final invalidControllerPage =
        pageIndex < 0 || pageIndex > (_locations.length - 1);

    if (invalidControllerPage && allowRecreate) {
      _recreatePageController(
        initialPage: safeIndex,
        reason: 'invalid_controller_page=$pageIndex/$reason',
      );
      if (mounted) {
        setState(() {});
      }
      return;
    }

    try {
      _pageController.jumpToPage(safeIndex);
    } catch (e) {
      if (allowRecreate) {
        _recreatePageController(
          initialPage: safeIndex,
          reason: 'jump_failure/$reason',
        );
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Future<void> _handleAppResumed() async {
    if (_isHandlingResumeCheck) {
      return;
    }

    final route = ModalRoute.of(context);
    final isRouteCurrent = route?.isCurrent ?? true;
    if (!isRouteCurrent && !_shouldDismissBlockingRouteOnResume) {
      return;
    }

    _isHandlingResumeCheck = true;

    try {
      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;
      await _dismissBlockingRouteOnResumeIfNeeded();

      final readinessError = await _locationService.getLocationReadiness();

      if (!mounted) return;

      if (readinessError != null) {
        if (_locations.isEmpty) {
          setState(() {
            _locationError = readinessError;
            _isLoading = false;
          });
        }
        _ensureNonBlankState();
        return;
      }

      if (_pendingSettingsReturn ||
          _locations.isEmpty ||
          _locationError != null) {
        await _loadAllLocations();
      } else {
        await _refreshCurrentLocation();
      }

      if (!mounted) return;
      await _ensurePageViewState(reason: 'resume', allowRecreate: true);
      _ensureNonBlankState();
    } catch (_) {
      if (!mounted) return;
      _ensureNonBlankState(
        fallbackMessage:
            'Unable to refresh weather after returning to the app.',
      );
    } finally {
      _pendingSettingsReturn = false;
      _shouldDismissBlockingRouteOnResume = false;
      _isHandlingResumeCheck = false;
    }
  }

  Future<void> _dismissBlockingRouteOnResumeIfNeeded() async {
    if (!_shouldDismissBlockingRouteOnResume || !mounted) {
      return;
    }

    final route = ModalRoute.of(context);
    final routeIsCovered = route != null && !route.isCurrent;
    final navigator = Navigator.of(context, rootNavigator: true);

    if (!routeIsCovered || !navigator.canPop()) {
      return;
    }

    await navigator.maybePop();
  }

  void _ensureNonBlankState({
    String fallbackMessage = 'Unable to load weather. Please try again.',
  }) {
    if (!mounted) return;

    if (_locations.isEmpty && !_isLoading && _locationError == null) {
      setState(() {
        _locationError = LocationResult.error(fallbackMessage);
        _isLoading = false;
      });
    }
  }

  void _initializeConnectivityMonitoring() {
    _connectivityService.startMonitoring((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });

        if (!isConnected) {
          _showSnackBar('⚠️ No internet connection');
        } else if (_locations.isEmpty) {
          // Regained connectivity, try loading again
          _loadAllLocations();
        }
      }
    });
  }

  Future<void> _initialize() async {
    await _loadSettings();
    await _loadInitialStreak();
    await _loadAllLocations();
    if (mounted) {
      setState(() => _animateIn = true);
    }
    _ensureNonBlankState();
  }

  Future<void> _loadInitialStreak() async {
    try {
      final streak = await _weatherStreakService.getCurrentStreak();
      if (mounted) {
        setState(() => _currentStreak = streak);
      }
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        _settingsService.getTemperatureUnit(),
        _settingsService.getWindSpeedUnit(),
      ]);

      if (mounted) {
        setState(() {
          _temperatureUnit = results[0] as TemperatureUnit;
          _windSpeedUnit = results[1] as WindSpeedUnit;
        });
      }
    } catch (_) {
      // Use defaults if loading fails
    }
  }

  Future<void> _loadAllLocations() async {
    if (!mounted) return;

    try {
      // Load saved locations first
      final savedLocations = await _savedLocationsService.getSavedLocations();
      if (!mounted) return;

      if (savedLocations.isEmpty) {
        // No saved locations - try cached weather first for instant display
        await _loadCachedWeatherThenRefresh();
        return;
      }

      // Show loading only if we have no data
      if (_locations.isEmpty) {
        setState(() => _isLoading = true);
      }

      // Load weather for all saved locations in parallel
      final futures = savedLocations.map((location) async {
        try {
          final snapshot = await _weatherService.fetchWeatherForLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: location.name,
          );

          return LocationWeatherData(location: location, snapshot: snapshot);
        } catch (_) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      if (!mounted) return;
      final locationDataList = results
          .whereType<LocationWeatherData>()
          .toList();

      if (locationDataList.isNotEmpty) {
        setState(() {
          _locations = locationDataList;
          _isLoading = false;
          _locationError = null;
        });
        await _ensurePageViewState(
          reason: 'load_all_locations_success',
          allowRecreate: false,
        );

        // Update current location in background if exists
        final hasCurrentLocation = _locations.any(
          (loc) => loc.location.isCurrent,
        );
        if (hasCurrentLocation) {
          _updateCurrentLocationInBackground();
        }
      } else if (_locations.isEmpty) {
        // All failed, try current location
        await _loadCurrentLocationWeather();
      }
    } catch (_) {
      if (!mounted) return;
      if (_locations.isEmpty) {
        await _loadCurrentLocationWeather();
      }
    }
  }

  Future<void> _loadCachedWeatherThenRefresh() async {
    try {
      // Try to show cached weather immediately
      final cachedLocation = await _locationService.getCachedLocation();

      if (cachedLocation != null &&
          cachedLocation.latitude != null &&
          cachedLocation.longitude != null &&
          cachedLocation.cityName != null) {
        // Fetch cached weather without showing loading
        await _fetchWeatherForNewLocation(
          cachedLocation.latitude!,
          cachedLocation.longitude!,
          cachedLocation.cityName!,
          isCurrent: true,
          showLoading: false,
        );
        // Then refresh in background
        _updateCurrentLocationInBackground();
      } else {
        // No cache - need to get current location (this handles GPS errors properly)
        await _loadCurrentLocationWeather();
      }
    } catch (_) {
      // Fall back to current location which handles errors properly
      await _loadCurrentLocationWeather();
    }
  }

  Future<void> _updateCurrentLocationInBackground() async {
    try {
      final locationResult = await _locationService.getCurrentLocation();

      if (locationResult.success &&
          locationResult.latitude != null &&
          locationResult.longitude != null &&
          locationResult.cityName != null) {
        await _fetchWeatherForNewLocation(
          locationResult.latitude!,
          locationResult.longitude!,
          locationResult.cityName!,
          isCurrent: true,
          showLoading: false,
        );
      } else if (_locations.isEmpty && mounted) {
        // Location failed and we have no data - show error screen
        setState(() {
          _locationError = locationResult;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentLocationWeather() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final locationResult = await _locationService.getCurrentLocation();

      if (locationResult.success &&
          locationResult.latitude != null &&
          locationResult.longitude != null &&
          locationResult.cityName != null) {
        await _fetchWeatherForNewLocation(
          locationResult.latitude!,
          locationResult.longitude!,
          locationResult.cityName!,
          isCurrent: true,
        );
      } else {
        if (mounted) {
          setState(() {
            _locationError = locationResult;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError = LocationResult.error('Network error occurred');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchWeatherForNewLocation(
    double latitude,
    double longitude,
    String cityName, {
    bool isCurrent = false,
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final snapshot = await _weatherService.fetchWeatherForLocation(
        latitude: latitude,
        longitude: longitude,
        locationName: cityName,
      );

      final location = SavedLocation(
        name: cityName,
        latitude: latitude,
        longitude: longitude,
        isCurrent: isCurrent,
      );

      if (isCurrent) {
        await _savedLocationsService.updateCurrentLocation(
          latitude,
          longitude,
          cityName,
        );
      }

      if (mounted) {
        setState(() {
          if (isCurrent) {
            // Update or add current location
            final existingIndex = _locations.indexWhere(
              (loc) => loc.location.isCurrent,
            );

            if (existingIndex != -1) {
              // Update existing current location
              _locations[existingIndex] = LocationWeatherData(
                location: location,
                snapshot: snapshot,
              );
            } else {
              // Add new current location at start
              _locations.insert(
                0,
                LocationWeatherData(location: location, snapshot: snapshot),
              );
              _currentPage = 0;
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            }
          } else {
            // Check if location already exists
            final existingIndex = _locations.indexWhere(
              (loc) =>
                  loc.location.latitude == latitude &&
                  loc.location.longitude == longitude,
            );

            if (existingIndex != -1) {
              // Update existing location
              _locations[existingIndex] = LocationWeatherData(
                location: location,
                snapshot: snapshot,
              );
            } else {
              // Add new location
              _locations.add(
                LocationWeatherData(location: location, snapshot: snapshot),
              );
            }
          }
          _isLoading = false;
          _locationError = null;
        });
        await _ensurePageViewState(
          reason: 'fetch_weather_for_new_location',
          allowRecreate: false,
        );

        // Update weather streak
        _updateWeatherStreak(snapshot.current.weatherCode);
      }
    } catch (_) {
      if (mounted && _locations.isEmpty) {
        setState(() {
          _locationError = LocationResult.error('Failed to fetch weather data');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshCurrentLocation() async {
    if (_isRefreshing || !mounted) return;

    try {
      setState(() => _isRefreshing = true);

      final currentIndex = _locations.indexWhere(
        (loc) => loc.location.isCurrent,
      );
      if (currentIndex != -1) {
        await _updateCurrentLocationInBackground();
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _updateWeatherStreak(int weatherCode) async {
    try {
      final streak = await _weatherStreakService.updateStreak(weatherCode);
      if (mounted) {
        setState(() => _currentStreak = streak);
      }
    } catch (_) {}
  }

  void _shareWeather() {
    if (_locations.isEmpty || _currentPage >= _locations.length) return;

    final data = _locations[_currentPage];
    final snapshot = data.snapshot;
    final today = snapshot.daily.isNotEmpty ? snapshot.daily.first : null;

    WeatherShareService.shareAsText(
      locationName: snapshot.locationName,
      temperature: snapshot.current.temperature,
      condition: snapshot.current.weatherDescription,
      high: today?.high ?? snapshot.current.temperature,
      low: today?.low ?? snapshot.current.temperature,
      tip: snapshot.tip.message,
    );
  }

  Future<void> _onSettingsChanged() async {
    await _loadSettings();
    if (mounted) setState(() {});
  }

  Future<void> _onLocationSelected(
    double latitude,
    double longitude,
    String cityName,
  ) async {
    HapticFeedback.mediumImpact();

    // Check if location already exists
    final existingIndex = _locations.indexWhere(
      (loc) =>
          loc.location.latitude == latitude &&
          loc.location.longitude == longitude,
    );

    if (existingIndex != -1) {
      // Location exists, just navigate to it
      setState(() => _currentPage = existingIndex);
      _pageController.animateToPage(
        existingIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _showSnackBar('Switched to ${cityName}');
      return;
    }

    // New location, fetch weather
    setState(() => _isLoading = true);
    await _fetchWeatherForNewLocation(latitude, longitude, cityName);

    if (mounted && _locations.isNotEmpty) {
      final newIndex = _locations.length - 1;
      setState(() => _currentPage = newIndex);
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _saveCurrentLocation() async {
    if (_currentPage >= _locations.length) return;

    HapticFeedback.mediumImpact();
    final currentLocation = _locations[_currentPage].location;

    if (currentLocation.isCurrent) {
      _showSnackBar('Current location is always available');
      return;
    }

    final count = await _savedLocationsService.getSavedLocationsCount();
    if (!_savedLocationsService.canSaveMore(count)) {
      _showSnackBar('You can save up to 5 locations');
      return;
    }

    final saved = await _savedLocationsService.saveLocation(currentLocation);
    if (saved) {
      HapticFeedback.heavyImpact();
      _showSnackBar('${currentLocation.name} saved successfully');
    } else {
      _showSnackBar('Location already saved');
    }
  }

  Future<void> _deleteLocation(SavedLocation location) async {
    HapticFeedback.mediumImpact();

    await _savedLocationsService.deleteLocation(location);

    if (mounted) {
      setState(() {
        final deletedIndex = _locations.indexWhere(
          (loc) =>
              loc.location.latitude == location.latitude &&
              loc.location.longitude == location.longitude,
        );

        if (deletedIndex != -1) {
          _locations.removeAt(deletedIndex);

          // Adjust current page if needed
          if (_currentPage >= _locations.length && _locations.isNotEmpty) {
            _currentPage = _locations.length - 1;
            _pageController.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }

          // If no locations left, load current location
          if (_locations.isEmpty) {
            _isLoading = true;
            _loadCurrentLocationWeather();
          }
        }
      });

      _showSnackBar('${location.name} removed');
    }
  }

  void _showAlertsDialog(List<UIWeatherAlert> alerts) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weather Alerts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: alerts.map((alert) {
                      final color = _getAlertColor(alert.severity);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getAlertIcon(alert.severity),
                                  color: color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  alert.title,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${alert.startsAt.toLocal().hour}:${alert.startsAt.toLocal().minute.toString().padLeft(2, '0')} - '
                              '${alert.endsAt.toLocal().hour}:${alert.endsAt.toLocal().minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor(AlertSeverity severity) {
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

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.minor:
        return Icons.info_outline;
      case AlertSeverity.moderate:
        return Icons.warning_amber_outlined;
      case AlertSeverity.severe:
        return Icons.warning_outlined;
      case AlertSeverity.extreme:
        return Icons.priority_high;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF38BDF8).withOpacity(0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    try {
      await _loadAllLocations();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _openSystemSettingsFlow({
    required bool openLocationSettings,
  }) async {
    _pendingSettingsReturn = true;
    _shouldDismissBlockingRouteOnResume = true;

    final opened = openLocationSettings
        ? await _locationService.openLocationSettings()
        : await _locationService.openAppSettings();

    if (!opened) {
      _pendingSettingsReturn = false;
      _shouldDismissBlockingRouteOnResume = false;
      if (!mounted) return;
      _showSnackBar('Could not open settings. Please open them manually.');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (AppLifecycleService.state.value == AppLifecycleState.resumed) {
      await _handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF020617);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          ConnectivityBanner(isOffline: _isOffline, onRetry: _handleRefresh),
          Expanded(child: SafeArea(child: _buildBodyContent())),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading && _locations.isEmpty) {
      return const WeatherSkeletonLoader();
    }

    if (_locations.isEmpty) {
      return _buildLocationErrorState(
        _locationError ??
            LocationResult.error('Unable to load weather. Please try again.'),
      );
    }

    if (!_animateIn && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _animateIn) return;
        setState(() => _animateIn = true);
      });
    }
    return _buildSwipeableContent();
  }

  Widget _buildLocationErrorState(LocationResult error) {
    final isGpsDisabled = error.errorType == LocationErrorType.serviceDisabled;
    final isPermissionDenied =
        error.errorType == LocationErrorType.permissionDenied;
    final isPermissionDeniedForever =
        error.errorType == LocationErrorType.permissionDeniedForever;
    final showSettingsButton = isGpsDisabled || isPermissionDeniedForever;
    final showGrantPermissionButton = isPermissionDenied;

    Future<void> openSystemSettings() async {
      await _openSystemSettingsFlow(openLocationSettings: isGpsDisabled);
    }

    Future<void> requestPermissionAgain() async {
      await _loadCurrentLocationWeather();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF38BDF8).withOpacity(0.15),
                  const Color(0xFF6366F1).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              isGpsDisabled
                  ? Icons.gps_off_rounded
                  : Icons.location_off_rounded,
              color: const Color(0xFF38BDF8),
              size: 42,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isGpsDisabled ? 'GPS is Turned Off' : 'Location Access Needed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Step-by-step instructions for GPS disabled
          if (isGpsDisabled) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildInstructionStep('1', 'Tap "Enable GPS" button below'),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    '2',
                    'Turn on Location/GPS in settings',
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep('3', 'Return to Auroclime'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Weather will load automatically!',
                          style: TextStyle(
                            color: const Color(0xFF10B981),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              error.errorMessage ?? 'Unable to determine your location.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 28),

          // Main action button
          if (showSettingsButton || showGrantPermissionButton)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: showGrantPermissionButton
                    ? requestPermissionAgain
                    : openSystemSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  showGrantPermissionButton
                      ? Icons.my_location
                      : (isGpsDisabled ? Icons.gps_fixed : Icons.settings),
                  size: 20,
                ),
                label: Text(
                  showGrantPermissionButton
                      ? 'Grant Permission'
                      : (isGpsDisabled ? 'Enable GPS' : 'Open App Settings'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Retry button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadCurrentLocationWeather,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Manual location option
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            child: const Text(
              'Or enter location manually',
              style: TextStyle(
                color: Colors.white54,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF38BDF8).withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeableContent() {
    if (_locations.isEmpty) {
      return _buildLocationErrorState(
        _locationError ??
            LocationResult.error('Unable to load weather. Please try again.'),
      );
    }

    final safeIndex = _safeCurrentPageIndex();
    if (safeIndex != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _ensurePageViewState(
          reason: 'build_swipeable_content_clamp',
          allowRecreate: false,
        );
      });
    }

    _schedulePageViewSync(
      reason: 'build_swipeable_content_sync',
      allowRecreate: true,
    );

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemCount: _locations.length,
          itemBuilder: (context, index) {
            if (index < 0 || index >= _locations.length) {
              return _buildPagePlaceholder(
                message: 'Preparing weather content for this location...',
              );
            }
            return _buildWeatherPage(_locations[index]);
          },
        ),
        if (_locations.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_locations.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 22 : 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF38BDF8)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildWeatherPage(LocationWeatherData data) {
    final isVisible = _animateIn || _locations.isNotEmpty;
    final effectiveOpacity = isVisible ? 1.0 : 0.0;

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 0.05),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: effectiveOpacity,
        duration: const Duration(milliseconds: 600),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF38BDF8),
          backgroundColor: const Color(0xFF0F172A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: _saveCurrentLocation,
                  child: WeatherHeader(
                    locationName: data.snapshot.locationName,
                    dateText: data.snapshot.dateText,
                    lastUpdatedText: data.snapshot.lastUpdatedText,
                    onSettingsChanged: _onSettingsChanged,
                    onLocationSelected: _onLocationSelected,
                    showDeleteButton:
                        !data.location.isCurrent && _locations.length > 1,
                    onDelete: () => _deleteLocation(data.location),
                    onShare: _shareWeather,
                  ),
                ),
                const SizedBox(height: 16),

                if (data.snapshot.alerts.isNotEmpty) ...[
                  WeatherAlertsBanner(
                    alerts: data.snapshot.alerts,
                    onTap: () => _showAlertsDialog(data.snapshot.alerts),
                  ),
                  const SizedBox(height: 12),
                ],

                // 1. Current Weather Card (with temperature and conditions)
                CurrentWeatherCard(
                  current: data.snapshot.current,
                  temperatureUnit: _temperatureUnit,
                  windSpeedUnit: _windSpeedUnit,
                ),
                const SizedBox(height: 16),

                // 2. Weather Streak (if exists)
                if (_currentStreak != null && _currentStreak!.hasStreak) ...[
                  WeatherStreakCard(streak: _currentStreak!),
                  const SizedBox(height: 16),
                ],

                // 3. Feels Different Card
                FeelsDifferentCard(
                  actualTemp: data.snapshot.current.temperature,
                  feelsLikeTemp: data.snapshot.current.feelsLike,
                ),
                const SizedBox(height: 16),

                // 4. Auroclime Tips
                AuroclimeTipCard(tip: data.snapshot.tip),
                const SizedBox(height: 16),

                // 3. Air Quality Index
                if (data.snapshot.airQuality != null) ...[
                  AirQualityCard(airQuality: data.snapshot.airQuality!),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildNoAQICard(),
                  const SizedBox(height: 16),
                ],

                // 4. UV Index Card
                UVIndexCard(uvIndex: data.snapshot.current.uvIndex),
                const SizedBox(height: 16),

                // 5. Weather Details Card (expandable)
                WeatherDetailsCard(
                  visibility: data.snapshot.current.visibility,
                  pressure: data.snapshot.current.pressure,
                  dewPoint: data.snapshot.current.dewPoint,
                  sunrise: data.snapshot.daily.isNotEmpty
                      ? data.snapshot.daily.first.sunrise
                      : null,
                  sunset: data.snapshot.daily.isNotEmpty
                      ? data.snapshot.daily.first.sunset
                      : null,
                ),
                const SizedBox(height: 24),

                // 6. Temperature Chart
                TemperatureChart(hourlyData: data.snapshot.hourly),
                const SizedBox(height: 16),

                // 7. Precipitation Chart
                PrecipitationChart(hourlyData: data.snapshot.hourly),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Next hours',
                  subtitle: 'Local time',
                ),
                const SizedBox(height: 12),
                HourlyForecastStrip(
                  items: data.snapshot.hourly,
                  temperatureUnit: _temperatureUnit,
                ),
                const SizedBox(height: 24),
                const _SectionTitle(
                  title: 'Next days',
                  subtitle: '7-day forecast',
                ),
                const SizedBox(height: 12),
                DailyForecastList(
                  items: data.snapshot.daily,
                  temperatureUnit: _temperatureUnit,
                ),
                const SizedBox(height: 16),
                FooterStatus(text: data.snapshot.footerStatusText),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagePlaceholder({required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAQICard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1e3a8a).withOpacity(0.15),
            const Color(0xFF1e40af).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF38BDF8).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF38BDF8).withOpacity(0.2),
                  const Color(0xFF0EA5E9).withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.air, color: Color(0xFF38BDF8), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Air Quality Index',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Data not available for this region',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              'N/A',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white38),
        ),
      ],
    );
  }
}

class LocationWeatherData {
  final SavedLocation location;
  final UIWeatherSnapshot snapshot;

  LocationWeatherData({required this.location, required this.snapshot});
}
