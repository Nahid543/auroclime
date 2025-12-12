import 'package:flutter/material.dart';
import '../../domain/settings_service.dart';
import '../../domain/location_service.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _locationService = LocationService();

  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  RefreshInterval _refreshInterval = RefreshInterval.thirtyMinutes;
  WindSpeedUnit _windSpeedUnit = WindSpeedUnit.kmh;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final tempUnit = await _settingsService.getTemperatureUnit();
    final refreshInterval = await _settingsService.getRefreshInterval();
    final windSpeedUnit = await _settingsService.getWindSpeedUnit();

    if (mounted) {
      setState(() {
        _temperatureUnit = tempUnit;
        _refreshInterval = refreshInterval;
        _windSpeedUnit = windSpeedUnit;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTemperatureUnit(TemperatureUnit unit) async {
    await _settingsService.setTemperatureUnit(unit);
    setState(() => _temperatureUnit = unit);
  }

  Future<void> _updateRefreshInterval(RefreshInterval interval) async {
    await _settingsService.setRefreshInterval(interval);
    setState(() => _refreshInterval = interval);
  }

  Future<void> _updateWindSpeedUnit(WindSpeedUnit unit) async {
    await _settingsService.setWindSpeedUnit(unit);
    setState(() => _windSpeedUnit = unit);
  }

  Future<void> _clearCache() async {
    await _locationService.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cache cleared successfully'),
          backgroundColor: const Color(0xFF38BDF8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF020617);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withOpacity(0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: 'Preferences'),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            child: Column(
                              children: [
                                _SettingsTile(
                                  icon: Icons.thermostat_rounded,
                                  title: 'Temperature Unit',
                                  subtitle: _temperatureUnit.label,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF38BDF8).withOpacity(0.2),
                                          const Color(0xFF6366F1).withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      _temperatureUnit.symbol,
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  onTap: _showTemperatureUnitDialog,
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                _SettingsTile(
                                  icon: Icons.air_rounded,
                                  title: 'Wind Speed Unit',
                                  subtitle: _windSpeedUnit.shortLabel,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF38BDF8).withOpacity(0.2),
                                          const Color(0xFF6366F1).withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      _windSpeedUnit.symbol,
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  onTap: _showWindSpeedUnitDialog,
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                _SettingsTile(
                                  icon: Icons.refresh_rounded,
                                  title: 'Auto-Refresh',
                                  subtitle: 'Update interval',
                                  trailing: Text(
                                    _refreshInterval.label,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: _showRefreshIntervalDialog,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionHeader(title: 'Data Management'),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            child: _SettingsTile(
                              icon: Icons.delete_sweep_rounded,
                              title: 'Clear Cache',
                              subtitle: 'Remove stored location data',
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                                size: 20,
                              ),
                              onTap: _clearCache,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionHeader(title: 'Notifications'),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            child: _SettingsTile(
                              icon: Icons.notifications_outlined,
                              title: 'Notification Settings',
                              subtitle: 'Manage weather alerts and reminders',
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                                size: 20,
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionHeader(title: 'About Auroclime'),
                          const SizedBox(height: 12),
                          _SettingsCard(
                            child: Column(
                              children: [
                                _SettingsTile(
                                  icon: Icons.info_outline_rounded,
                                  title: 'Version',
                                  subtitle: 'App version',
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                    child: const Text(
                                      '1.0.0',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  onTap: () {},
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                _SettingsTile(
                                  icon: Icons.cloud_outlined,
                                  title: 'Weather Provider',
                                  subtitle: 'Open-Meteo API',
                                  trailing: Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 18,
                                  ),
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: Column(
                              children: [
                                // Auroclime Logo
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8)
                                            .withOpacity(0.3),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/auroclime_icon.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Auroclime',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Modern weather, beautifully designed',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white38,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemperatureUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF38BDF8).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.thermostat_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Temperature Unit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _RadioTile(
                title: 'Celsius (°C)',
                subtitle: 'Metric system',
                value: TemperatureUnit.celsius,
                groupValue: _temperatureUnit,
                onChanged: (value) {
                  _updateTemperatureUnit(value!);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _RadioTile(
                title: 'Fahrenheit (°F)',
                subtitle: 'Imperial system',
                value: TemperatureUnit.fahrenheit,
                groupValue: _temperatureUnit,
                onChanged: (value) {
                  _updateTemperatureUnit(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWindSpeedUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF38BDF8).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Wind Speed Unit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...WindSpeedUnit.values.map((unit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RadioTile(
                    title: unit.symbol,
                    subtitle: unit.shortLabel,
                    value: unit,
                    groupValue: _windSpeedUnit,
                    onChanged: (value) {
                      _updateWindSpeedUnit(value!);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefreshIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF38BDF8).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Auto-Refresh Interval',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...RefreshInterval.values.map((interval) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RadioTile(
                    title: interval.label,
                    subtitle: 'Update weather every ${interval.minutes} min',
                    value: interval,
                    groupValue: _refreshInterval,
                    onChanged: (value) {
                      _updateRefreshInterval(value!);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF38BDF8),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.01),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF38BDF8).withOpacity(0.15),
                    const Color(0xFF6366F1).withOpacity(0.15),
                  ],
                ),
              ),
              child: Icon(icon, color: const Color(0xFF38BDF8), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? const Color(0xFF38BDF8).withOpacity(0.12)
              : Colors.white.withOpacity(0.02),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8).withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
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
