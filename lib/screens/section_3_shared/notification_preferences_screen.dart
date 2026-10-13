import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/notification_provider.dart';
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
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final prefs = await context.read<NotificationProvider>().getPreferences();
      if (mounted) {
        setState(() => _prefs = prefs);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePreference(NotificationPreferences newPrefs) async {
    final previousPrefs = _prefs!;
    setState(() {
      _prefs = newPrefs;
      _isSaving = true;
    });

    try {
      await context.read<NotificationProvider>().updatePreferences(newPrefs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = previousPrefs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to save notification preferences.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            const AppHeader(title: 'Notification Preferences'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_outlined, color: colorScheme.error, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load notification preferences.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadPreferences,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final prefs = _prefs!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: IgnorePointer(
        ignoring: _isSaving,
        child: Column(
        children: [
          const AppHeader(title: 'Notification Preferences'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
            subtitle: 'Receive booking updates by email.',
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
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
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
      activeThumbColor: colorScheme.surface,
      activeTrackColor: colorScheme.primary,
      secondary: icon != null ? Icon(icon, color: colorScheme.onSurfaceVariant, size: 22) : null,
      title: Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      subtitle: subtitle != null ? Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: colorScheme.onSurfaceVariant)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
