import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';

/// Security Settings Screen (0.8)
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  DateTime? _deletionRequestedAt;
  bool _deletionStatusLoaded = false;
  bool _deletionStatusFailed = false;
  bool _isUpdatingDeletionRequest = false;

  Future<void> _loadDeletionRequestStatus() async {
    final result = await context.read<AuthProvider>().getDeletionRequestStatus();
    if (!mounted) return;
    setState(() {
      _deletionStatusLoaded = true;
      _deletionStatusFailed = !result.success;
      if (result.success) {
        _deletionRequestedAt = DateTime.tryParse(
          result.data?['deletion_requested_at']?.toString() ?? '',
        );
      }
    });
  }

  Future<void> _updateDeletionRequest({required bool cancel}) async {
    final result = cancel
        ? await context.read<AuthProvider>().cancelAccountDeletion()
        : await context.read<AuthProvider>().requestAccountDeletion();
    if (!mounted) return;

    setState(() {
      _isUpdatingDeletionRequest = false;
      _deletionStatusFailed = !result.success;
      if (result.success) {
        _deletionRequestedAt = DateTime.tryParse(
          result.data?['deletion_requested_at']?.toString() ?? '',
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
    if (result.success && result.data?['deletion_requested_at'] is! String) {
      await _loadDeletionRequestStatus();
    }
  }

  Future<void> _confirmDeletionRequest({required bool cancel}) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cancel ? 'Cancel deletion request?' : 'Request account deletion?'),
        content: Text(
          cancel
              ? 'Your pending request will be withdrawn. Your account and data will remain available.'
              : 'This submits a request for an admin to review; your account will not be deleted immediately. You can cancel the request while it is pending. Some records may be retained where required for safety, disputes, or legal obligations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              cancel ? 'Cancel Request' : 'Submit Request',
              style: TextStyle(
                color: cancel ? colorScheme.primary : colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isUpdatingDeletionRequest = true);
    await _updateDeletionRequest(cancel: cancel);
  }

  Future<void> _handleSignOut() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out of All Devices'),
        content: const Text('This will sign you out of all devices where you are currently logged in. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await context.read<AuthProvider>().revokeAllSessions();
      if (!mounted) return;
      if (result.success) {
        await context.read<AuthProvider>().logout();
      }
      if (mounted && result.success) {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: theme.colorScheme.error),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().loadTwoFactorPreference();
    _loadDeletionRequestStatus();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final linkedEmail = authProvider.userEmail ?? '';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          AppHeader(
            title: 'Security Settings',
            onBackPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, authProvider.getHomeRoute());
              }
            },
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Settings Card
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Row 1: Change Password
                        _buildSettingsRow(
                          title: authProvider.isGoogleLinked ? 'Set a Password' : 'Change Password',
                          onTap: () => Navigator.pushNamed(context, AppRouter.changePassword),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        
                        // Row 2: Linked Accounts
                        _buildSettingsRow(
                          title: 'Google Sign-In Status',
                          subtitle: authProvider.isGoogleLinked
                              ? 'Google account linked: $linkedEmail'
                              : 'No Google account linked',
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        
                        // Row 3: Two-Factor Authentication
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Two-Factor Authentication', style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enhance security by requiring an email OTP code when you log in.',
                                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: authProvider.twoFactorEnabled,
                                activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                                activeThumbColor: colorScheme.primary,
                                onChanged: (val) async {
                                  final updated = await authProvider.updateTwoFactorPreference(val);
                                  if (!updated && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Unable to update two-factor authentication.')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        
                        // Row 4: Login Activity
                        _buildSettingsRow(
                          title: 'Login Activity',
                          onTap: () => Navigator.pushNamed(context, AppRouter.loginActivity),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildDeletionRequestCard(colorScheme),

                  const SizedBox(height: 32),
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _handleSignOut,
                      style: TextButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Sign Out of All Devices',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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
    );
  }

  Widget _buildDeletionRequestCard(ColorScheme colorScheme) {
    final isPending = _deletionRequestedAt != null;
    final requestedDate = _deletionRequestedAt?.toLocal();
    final dateLabel = requestedDate == null
        ? null
        : '${requestedDate.year}-${requestedDate.month.toString().padLeft(2, '0')}-${requestedDate.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Deletion',
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPending
                ? 'Your request is pending admin review${dateLabel == null ? '.' : ' (submitted $dateLabel).'} You can withdraw it before it is processed.'
                : 'Request that an admin review and process deletion of your account.',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (!_deletionStatusLoaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_deletionStatusFailed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Unable to load your request status.',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadDeletionRequestStatus,
                  child: const Text('Retry'),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isUpdatingDeletionRequest
                    ? null
                    : () => _confirmDeletionRequest(cancel: isPending),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isPending ? colorScheme.primary : colorScheme.error,
                  side: BorderSide(
                    color: isPending
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.error.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: _isUpdatingDeletionRequest
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isPending
                            ? 'Withdraw Deletion Request'
                            : 'Request Account Deletion',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
