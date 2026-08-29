import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/service_locator.dart';
import '../../data/models/notification_model.dart';
import '../../widgets/navigation/app_header.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  NotificationPreferences? _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await notificationRepository.getPreferences();
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _isLoading = false;
      });
    }
  }

  void _updatePreference(NotificationPreferences newPrefs) {
    setState(() => _prefs = newPrefs);
    notificationRepository.updatePreferences(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final prefs = _prefs!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildCategoriesCard(prefs),
                  const SizedBox(height: 24),
                  _buildChannelsCard(prefs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            const BackButton(color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Notification Preferences',
              style: AppTypography.headlineMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCard(NotificationPreferences prefs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Notification Categories'),
          _buildToggleRow(
            title: 'Booking Updates',
            subtitle: 'Receive updates about your booking status and appointments.',
            value: prefs.bookingUpdates,
            onChanged: (val) => _updatePreference(prefs.copyWith(bookingUpdates: val)),
          ),
          const Divider(height: 1),
          _buildToggleRow(
            title: 'Messages',
            subtitle: 'Get notified when someone sends you a message.',
            value: prefs.messages,
            onChanged: (val) => _updatePreference(prefs.copyWith(messages: val)),
          ),
          const Divider(height: 1),
          _buildToggleRow(
            title: 'Promotions & Announcements',
            subtitle: 'Stay updated on new features and special offers.',
            value: prefs.promotions,
            onChanged: (val) => _updatePreference(prefs.copyWith(promotions: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsCard(NotificationPreferences prefs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Channels'),
          _buildToggleRow(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            value: prefs.pushEnabled,
            onChanged: (val) => _updatePreference(prefs.copyWith(pushEnabled: val)),
          ),
          const Divider(height: 1),
          _buildToggleRow(
            icon: Icons.mail_outline,
            title: 'Email Notifications',
            value: prefs.emailEnabled,
            onChanged: (val) => _updatePreference(prefs.copyWith(emailEnabled: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surfaceContainerLow,
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildToggleRow({
    IconData? icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: AppColors.primary,
      secondary: icon != null ? Icon(icon, color: AppColors.onSurfaceVariant, size: 22) : null,
      title: Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
