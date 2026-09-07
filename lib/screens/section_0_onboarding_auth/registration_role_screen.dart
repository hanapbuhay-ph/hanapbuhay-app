import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/google_signin_button.dart';

/// Registration — Role Selection Screen
class RegistrationRoleScreen extends StatefulWidget {
  const RegistrationRoleScreen({super.key});

  @override
  State<RegistrationRoleScreen> createState() => _RegistrationRoleScreenState();
}

class _RegistrationRoleScreenState extends State<RegistrationRoleScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  void _onContinueManual() {
    if (_selectedRole == null) return;
    Navigator.pushNamed(context, '${AppRouter.registerAccount}?role=$_selectedRole');
  }

  Future<void> _onContinueWithGoogle() async {
    if (_selectedRole == null) return;
    final ap = context.read<AuthProvider>();
    // If user just came from Login Google (already authenticated, is_new_user without role), don't re-trigger Google.
    // Go straight to Complete Profile with the role they just picked.
    if (ap.isAuthenticated && (ap.userRole == null || ap.userRole!.isEmpty)) {
      if (!mounted) return;
      Navigator.pushNamed(context, '${AppRouter.completeProfile}?role=$_selectedRole');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ap.googleLogin(roleForNewUser: _selectedRole, forceAccountPicker: true);
      if (!mounted) return;
      if (result.success) {
        final d = result.data ?? {};
        final isNew = d['is_new_user'] == true || d['needs_profile_completion'] == true || d['isNewUser'] == true;
        final user = d['user'] is Map ? (d['user'] as Map) : null;
        final roleMissing = user != null && (user['role'] == null || user['role'].toString().isEmpty || user['role'].toString() == 'null');
        final needsComplete = isNew || roleMissing;
        if (needsComplete) {
          Navigator.pushNamed(context, '${AppRouter.completeProfile}?role=$_selectedRole');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This Google account is already registered. Redirecting to login.')),
          );
          Navigator.pushReplacementNamed(context, context.read<AuthProvider>().getHomeRoute());
        }
      } else {
        if (result.message != 'Google sign-in cancelled.') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: Theme.of(context).colorScheme.error));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Step 1 of 2',
                    style: AppTypography.labelLarge.copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How will you use HanapBuhay?',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(fontSize: 28, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your primary role to customize your experience.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  _RoleCard(
                    title: 'I want to hire',
                    description: 'Find skilled workers for your tasks and projects.',
                    icon: Icons.search,
                    iconBgColor: colorScheme.secondaryContainer,
                    iconColor: colorScheme.onSecondaryContainer,
                    isSelected: _selectedRole == 'client',
                    onTap: () => setState(() => _selectedRole = 'client'),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    title: 'I want to work',
                    description: 'Offer your skills and find job opportunities.',
                    icon: Icons.build,
                    iconBgColor: colorScheme.tertiaryContainer,
                    iconColor: colorScheme.onTertiaryContainer,
                    isSelected: _selectedRole == 'worker',
                    onTap: () => setState(() => _selectedRole = 'worker'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: 'Continue',
                  showArrow: true,
                  isLoading: _isLoading,
                  onPressed: _selectedRole != null && !_isLoading ? _onContinueManual : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or', 
                        style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
                  ],
                ),
                const SizedBox(height: 20),
                GoogleSignInButton(
                  isLoading: _isLoading,
                  onPressed: _selectedRole != null && !_isLoading ? _onContinueWithGoogle : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.headlineMedium.copyWith(fontSize: 20, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: colorScheme.onPrimary, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
