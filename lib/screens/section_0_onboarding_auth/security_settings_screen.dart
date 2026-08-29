import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';

/// Security Settings Screen (0.8)
/// 
/// Allows users to manage their account security, including changing password,
/// viewing linked accounts, and signing out.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactorEnabled = false;

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of all devices?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        context.go(AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final linkedEmail = authProvider.userEmail ?? 'Not linked';

    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFB), // Surface Cream
      body: Column(
        children: [
          AppHeader(
            title: 'Security Settings',
            onBackPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(authProvider.getHomeRoute());
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Row 1: Change Password
                        _buildSettingsRow(
                          title: 'Change Password',
                          onTap: () => context.push(AppRouter.changePassword),
                        ),
                        const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                        
                        // Row 2: Linked Accounts
                        _buildSettingsRow(
                          title: 'Linked Accounts',
                          subtitle: 'Google account linked: $linkedEmail',
                          onTap: () {
                            // TODO: Linked Accounts screen not in current scope
                            debugPrint('Navigate to Linked Accounts');
                          },
                        ),
                        const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                        
                        // Row 3: Two-Factor Authentication
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Two-Factor Authentication', style: AppTypography.bodyLarge),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add an extra layer of security to your account.',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _twoFactorEnabled,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  // TODO: 2FA is non-functional until backend support
                                  setState(() => _twoFactorEnabled = val);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('2FA is coming soon!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                        
                        // Row 4: Login Activity
                        _buildSettingsRow(
                          title: 'Login Activity',
                          onTap: () {
                            // TODO: Login Activity screen not in current scope
                            debugPrint('Navigate to Login Activity');
                          },
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
                        backgroundColor: AppColors.errorContainer.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Sign Out of All Devices',
                        style: TextStyle(
                          color: AppColors.error,
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
                  Text(title, style: AppTypography.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
