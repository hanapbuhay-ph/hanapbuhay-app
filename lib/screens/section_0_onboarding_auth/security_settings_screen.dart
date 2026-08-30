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
  final bool _twoFactorEnabled = true; // Email OTP is mandatory in this app

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
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
      }
    }
  }

  void _showLinkedAccountsInfo() {
    final authProvider = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Linked Accounts'),
        content: Text(
          authProvider.isGoogleLinked 
            ? 'Your account is currently linked with your Google account (${authProvider.userEmail}). This allows you to log in quickly using Google Sign-In.'
            : 'You are currently using email and password to log in. You can link a Google account during the registration process.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final linkedEmail = authProvider.userEmail ?? '';

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                          title: 'Change Password',
                          onTap: () => Navigator.pushNamed(context, AppRouter.changePassword),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        
                        // Row 2: Linked Accounts
                        _buildSettingsRow(
                          title: 'Linked Accounts',
                          subtitle: authProvider.isGoogleLinked ? 'Google account linked: $linkedEmail' : 'Manage your connected social accounts',
                          onTap: _showLinkedAccountsInfo,
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
                                      'Email verification is required for all accounts and cannot be disabled.',
                                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _twoFactorEnabled,
                                activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                                activeColor: colorScheme.primary,
                                onChanged: null, // Disabled as mandatory
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

  Widget _buildSettingsRow({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
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
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
