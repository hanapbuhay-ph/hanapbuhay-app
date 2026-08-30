import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../services/google_auth_service.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/google_signin_button.dart';

/// Registration — Role Selection Screen
/// 
/// Refactored to avoid "stacked" overlays. The footer is now part of the 
/// main layout Column, and the content area is scrollable in between.
class RegistrationRoleScreen extends StatefulWidget {
  const RegistrationRoleScreen({super.key});

  @override
  State<RegistrationRoleScreen> createState() => _RegistrationRoleScreenState();
}

class _RegistrationRoleScreenState extends State<RegistrationRoleScreen> {
  String? _selectedRole;

  void _onContinueManual() {
    if (_selectedRole == null) return;
    // We use push to keep the back stack for this registration wizard
    Navigator.pushNamed(context, '${AppRouter.registerAccount}?role=$_selectedRole');
  }

  Future<void> _onContinueWithGoogle() async {
    if (_selectedRole == null) return;
    await GoogleAuthService().signIn();
    if (mounted) {
      Navigator.pushNamed(context, '${AppRouter.completeProfile}?role=$_selectedRole');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFB), // Surface Cream
      body: Column(
        children: [
          // 1. Standardized Header
          const AppHeader(),

          // 2. Scrollable Selection Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Step 1 of 2',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How will you use HanapBuhay?',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your primary role to customize your experience.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  _RoleCard(
                    title: 'I want to hire',
                    description: 'Find skilled workers for your tasks and projects.',
                    icon: Icons.search,
                    iconBgColor: AppColors.secondaryContainer,
                    iconColor: AppColors.onSecondaryContainer,
                    isSelected: _selectedRole == 'client',
                    onTap: () => setState(() => _selectedRole = 'client'),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    title: 'I want to work',
                    description: 'Offer your skills and find job opportunities.',
                    icon: Icons.build,
                    iconBgColor: const Color(0xFFFFDDB5),
                    iconColor: const Color(0xFF835400),
                    isSelected: _selectedRole == 'worker',
                    onTap: () => setState(() => _selectedRole = 'worker'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // 3. Fixed Bottom Navigation (Not an overlay anymore)
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: const Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: 'Continue',
                  showArrow: true,
                  onPressed: _selectedRole != null ? _onContinueManual : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or', 
                        style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 20),
                GoogleSignInButton(
                  onPressed: _selectedRole != null ? _onContinueWithGoogle : null,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryContainer.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              const BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Ensure internal content respects corners
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
                        style: AppTypography.headlineMedium.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
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
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

