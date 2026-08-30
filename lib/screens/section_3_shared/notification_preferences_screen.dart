import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/notification_model.dart';

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
    final prefs = await context.read<NotificationProvider>().getPreferences();
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _isLoading = false;
      });
    }
  }

  void _updatePreference(NotificationPreferences newPrefs) {
    setState(() => _prefs = newPrefs);
    context.read<NotificationProvider>().updatePreferences(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    final prefs = _prefs!;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            BackButton(color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Notification Preferences',
              style: AppTypography.headlineMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCard(NotificationPreferences prefs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          _buildToggleRow(
            title: 'Messages',
            subtitle: 'Get notified when someone sends you a message.',
            value: prefs.messages,
            onChanged: (val) => _updatePreference(prefs.copyWith(messages: val)),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: colorScheme.surfaceVariant.withValues(alpha: 0.1),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.surface,
      activeTrackColor: colorScheme.primary,
      secondary: icon != null ? Icon(icon, color: colorScheme.onSurfaceVariant, size: 22) : null,
      title: Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      subtitle: subtitle != null ? Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: colorScheme.onSurfaceVariant)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
