import 'package:flutter/material.dart';
import '../../domain/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _notificationService = NotificationService();

  bool _dailySummaryEnabled = false;
  bool _severeAlertsEnabled = true;
  bool _precipitationEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 7, minute: 0);
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _notificationService.initialize();

    final hasPermission = await _notificationService.hasPermission();
    final dailyEnabled = await _notificationService.isDailySummaryEnabled();
    final severeEnabled = await _notificationService.isSevereAlertsEnabled();
    final precipEnabled =
        await _notificationService.isPrecipitationAlertsEnabled();

    final timeMap = await _notificationService.getDailySummaryTime();
    final time = TimeOfDay(
      hour: timeMap['hour']!,
      minute: timeMap['minute']!,
    );

    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _dailySummaryEnabled = dailyEnabled;
        _severeAlertsEnabled = severeEnabled;
        _precipitationEnabled = precipEnabled;
        _notificationTime = time;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermission();
    setState(() => _hasPermission = granted);

    if (!granted && mounted) {
      _showSnackBar('Please enable notifications in app settings');
    }
  }

  Future<void> _toggleDailySummary(bool value) async {
    if (!_hasPermission) {
      await _requestPermission();
      if (!_hasPermission) return;
    }

    if (value) {
      await _notificationService.enableDailySummary(
        _notificationTime.hour,
        _notificationTime.minute,
      );
    } else {
      await _notificationService.disableDailySummary();
    }

    setState(() => _dailySummaryEnabled = value);
    _showSnackBar(value ? 'Daily summary enabled' : 'Daily summary disabled');
  }

  Future<void> _toggleSevereAlerts(bool value) async {
    if (!_hasPermission && value) {
      await _requestPermission();
      if (!_hasPermission) return;
    }

    if (value) {
      await _notificationService.enableSevereAlerts();
    } else {
      await _notificationService.disableSevereAlerts();
    }

    setState(() => _severeAlertsEnabled = value);
  }

  Future<void> _togglePrecipitation(bool value) async {
    if (!_hasPermission && value) {
      await _requestPermission();
      if (!_hasPermission) return;
    }

    if (value) {
      await _notificationService.enablePrecipitationAlerts();
    } else {
      await _notificationService.disablePrecipitationAlerts();
    }

    setState(() => _precipitationEnabled = value);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF0F172A),
              dialBackgroundColor: const Color(0xFF1E293B),
              dialHandColor: const Color(0xFF38BDF8),
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white70,
              dayPeriodColor: const Color(0xFF38BDF8).withOpacity(0.2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null && mounted) {
      setState(() => _notificationTime = time);

      if (_dailySummaryEnabled) {
        await _notificationService.enableDailySummary(time.hour, time.minute);
        _showSnackBar('Notification time updated');
      }
    }
  }

  Future<void> _sendTestNotification() async {
    if (!_hasPermission) {
      await _requestPermission();
      if (!_hasPermission) return;
    }

    await _notificationService.sendTestNotification();
    _showSnackBar('Test notification sent!');
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

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF020617);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF38BDF8),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Permission Card
                          if (!_hasPermission)
                            _buildPermissionCard()
                          else
                            _buildPermissionGrantedCard(),

                          const SizedBox(height: 24),

                          // Daily Summary Section
                          _buildSectionHeader('Daily Summary'),
                          const SizedBox(height: 12),
                          _buildNotificationCard(
                            icon: Icons.wb_sunny_outlined,
                            title: 'Daily Weather Summary',
                            subtitle: 'Get morning forecast at ${_notificationTime.format(context)}',
                            value: _dailySummaryEnabled,
                            onChanged: _toggleDailySummary,
                            actions: _dailySummaryEnabled
                                ? [
                                    _buildTimeButton(),
                                  ]
                                : null,
                          ),

                          const SizedBox(height: 24),

                          // Alerts Section
                          _buildSectionHeader('Weather Alerts'),
                          const SizedBox(height: 12),
                          _buildNotificationCard(
                            icon: Icons.warning_amber_rounded,
                            title: 'Severe Weather Alerts',
                            subtitle: 'Get notified about dangerous conditions',
                            value: _severeAlertsEnabled,
                            onChanged: _toggleSevereAlerts,
                          ),
                          const SizedBox(height: 12),
                          _buildNotificationCard(
                            icon: Icons.water_drop_outlined,
                            title: 'Precipitation Alerts',
                            subtitle: 'Notify when rain is expected soon',
                            value: _precipitationEnabled,
                            onChanged: _togglePrecipitation,
                          ),

                          const SizedBox(height: 32),

                          // Test Button
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _sendTestNotification,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF38BDF8),
                                side: const BorderSide(
                                  color: Color(0xFF38BDF8),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.notifications_outlined),
                              label: const Text(
                                'Send Test Notification',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.15),
            const Color(0xFFF97316).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: Color(0xFFEF4444),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Notifications Disabled',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Enable notifications to receive weather updates and alerts.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _requestPermission,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Enable Notifications',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGrantedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.15),
            const Color(0xFF059669).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Color(0xFF10B981),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications enabled',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF38BDF8),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    List<Widget>? actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF38BDF8).withOpacity(0.15),
                        const Color(0xFF6366F1).withOpacity(0.15),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: const Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF38BDF8),
                  activeTrackColor: const Color(0xFF38BDF8).withOpacity(0.5),
                ),
              ],
            ),
          ),
          if (actions != null) ...[
            Divider(
              height: 1,
              color: Colors.white.withOpacity(0.06),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton() {
    return OutlinedButton.icon(
      onPressed: _selectTime,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF38BDF8),
        side: BorderSide(
          color: const Color(0xFF38BDF8).withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.schedule, size: 18),
      label: Text(
        _notificationTime.format(context),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
