import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/trust_tier.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  Worker? _workerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userRole == 'worker') {
      final workerProvider = context.read<WorkerProvider>();
      final worker = await workerProvider.getWorkerById('w1');
      if (mounted) {
        setState(() {
          _workerData = worker;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isWorker = authProvider.userRole == 'worker';
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }

    return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account and preferences.',
                          style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUserSummary(authProvider),
                  if (isWorker) ...[
                    const SizedBox(height: 24),
                    _buildTrustTierCard(isWorker),
                    const SizedBox(height: 16),
                    _buildQuickStats(isWorker),
                  ],
                  const SizedBox(height: 32),
                  _buildAccountOptions(isWorker),
                  const SizedBox(height: 24),
                  _buildPreferencesCard(isWorker),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildUserSummary(AuthProvider authProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = authProvider.userName ?? _workerData?.name ?? 'User';
    final bio = _workerData?.bio ?? 'Passionate about finding quality services in our community.';
    final avatar = authProvider.userAvatar ?? _workerData?.avatarUrl ?? 'https://i.pravatar.cc/150?u=client';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.surfaceVariant,
                backgroundImage: avatar.startsWith('http') 
                    ? NetworkImage(avatar) 
                    : FileImage(File(avatar)) as ImageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRouter.editProfile),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                    child: Icon(Icons.edit, size: 14, color: colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: AppTypography.headlineMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  authProvider.userRole == 'worker' ? Icons.work : Icons.person,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  authProvider.userRole?.toUpperCase() ?? 'CLIENT',
                  style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if ((authProvider.userBarangay ?? _workerData?.barangay) != null)
            Text(
              '📍 ${authProvider.userBarangay ?? _workerData!.barangay}',
              style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _buildTrustTierCard(bool isWorker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trustInfo = isWorker ? _workerData?.trustTier.info : TrustTier.verified.info;
    
    final label = trustInfo?.label ?? 'Standard';
    final color = trustInfo?.color ?? colorScheme.onSurfaceVariant;
    final icon = trustInfo?.icon ?? Icons.shield_outlined;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRUST TIER', style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
                Row(
                  children: [
                    Flexible(
                      child: Text(label, style: AppTypography.headlineMedium.copyWith(fontSize: 18, color: color, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    ),
                    if (isWorker && _workerData?.trustTier != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.check_circle, color: color, size: 18),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isWorker) {
    final theme = Theme.of(context);
    final rating = isWorker ? (_workerData?.rating ?? 0.0) : 5.0;
    final jobs = isWorker ? (_workerData?.completedJobsCount ?? 0) : 12;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(rating.toString(), 'Rating', Icons.star, Colors.amber),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(jobs.toString(), isWorker ? 'Jobs Done' : 'Bookings', Icons.task_alt, theme.colorScheme.secondary),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineMedium.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOptions(bool isWorker) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Account Options'),
          _buildOptionRow(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your personal details',
            onTap: () => Navigator.pushNamed(context, AppRouter.editProfile),
          ),
          if (isWorker) ...[
            const Divider(height: 1),
            _buildOptionRow(
              icon: Icons.post_add_outlined,
              title: 'Manage Posts',
              subtitle: 'View and manage your job listings',
              onTap: () => Navigator.pushNamed(context, AppRouter.manageJobPosts),
            ),
            const Divider(height: 1),
            _buildOptionRow(
              icon: Icons.verified_user_outlined,
              title: 'Verification Status',
              subtitle: 'Manage trust documents',
              trailing: _buildStatusBadge(_workerData?.verificationStatus ?? VerificationStatus.notStarted),
              onTap: () => Navigator.pushNamed(context, AppRouter.verificationStatus),
            ),
            const Divider(height: 1),
            _buildOptionRow(
              icon: Icons.architecture_outlined,
              title: 'Portfolio & Skills',
              subtitle: 'Showcase your work history',
              onTap: () => Navigator.pushNamed(context, AppRouter.portfolioSkills),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(bool isWorker) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Preferences'),
          _buildOptionRow(
            icon: Icons.security_outlined,
            title: 'Security Settings',
            onTap: () => Navigator.pushNamed(context, AppRouter.securitySettings),
          ),
          const Divider(height: 1),
          _buildOptionRow(
            icon: Icons.notifications_none_outlined,
            title: 'Notification Preferences',
            onTap: () => Navigator.pushNamed(context, AppRouter.notificationPreferences),
          ),
          if (!isWorker) ...[
            const Divider(height: 1),
            _buildOptionRow(
              icon: Icons.flag_outlined,
              title: 'My Reports',
              onTap: () => Navigator.pushNamed(context, AppRouter.reportStatus),
            ),
          ],
          const Divider(height: 1),
          _buildOptionRow(
            icon: Icons.help_outline,
            title: 'Help / FAQ',
            onTap: () => Navigator.pushNamed(context, AppRouter.help),
          ),
          const Divider(height: 1),
          _buildOptionRow(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            onTap: _showAppearancePicker,
          ),
        ],
      ),
    );
  }

  void _showAppearancePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AppearanceBottomSheet(),
    );
  }

  Widget _buildCardHeader(String title) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle, style: AppTypography.bodySmall) : null,
      trailing: Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outlineVariant),
      onTap: onTap,
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    final theme = Theme.of(context);
    String label = 'NOT STARTED';
    Color color = theme.colorScheme.onSurfaceVariant;

    switch (status) {
      case VerificationStatus.verified:
        label = 'ACTIVE';
        color = theme.colorScheme.primary;
        break;
      case VerificationStatus.pending:
        label = 'PENDING';
        color = Colors.amber;
        break;
      case VerificationStatus.rejected:
        label = 'REJECTED';
        color = theme.colorScheme.error;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _handleLogout,
        icon: Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
        label: Text('Logout', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w800, fontSize: 16)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _AppearanceBottomSheet extends StatelessWidget {
  const _AppearanceBottomSheet();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Appearance',
            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 32),
          _buildThemeOption(
            context,
            mode: ThemeMode.system,
            label: 'System Default',
            icon: Icons.brightness_auto_outlined,
            isSelected: currentMode == ThemeMode.system,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            mode: ThemeMode.light,
            label: 'Light Mode',
            icon: Icons.light_mode_outlined,
            isSelected: currentMode == ThemeMode.light,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            mode: ThemeMode.dark,
            label: 'Dark Mode',
            icon: Icons.dark_mode_outlined,
            isSelected: currentMode == ThemeMode.dark,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: () {
        context.read<ThemeProvider>().setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
