import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/client_bottom_nav.dart';
import '../../widgets/navigation/worker_bottom_nav.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
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

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFB), // Surface Cream
      body: Column(
        children: [
          _buildHeader(authProvider),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildUserSummary(authProvider),
                  const SizedBox(height: 24),
                  _buildTrustTierCard(isWorker),
                  const SizedBox(height: 16),
                  _buildQuickStats(isWorker),
                  const SizedBox(height: 32),
                  _buildAccountOptions(isWorker),
                  const SizedBox(height: 24),
                  _buildPreferencesCard(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWorker 
          ? const WorkerBottomNav(currentIndex: 4) 
          : const ClientBottomNav(currentIndex: 4),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    final avatar = authProvider.userAvatar ?? _workerData?.avatarUrl ?? 'https://i.pravatar.cc/150?u=client';

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            const Spacer(),
            Text('Profile', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            CircleAvatar(
              radius: 18, 
              backgroundImage: avatar.startsWith('http') 
                  ? NetworkImage(avatar) 
                  : FileImage(File(avatar)) as ImageProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSummary(AuthProvider authProvider) {
    final name = authProvider.userName ?? _workerData?.name ?? 'User';
    final bio = _workerData?.bio ?? 'Passionate about finding quality services in our community.';
    final avatar = authProvider.userAvatar ?? _workerData?.avatarUrl ?? 'https://i.pravatar.cc/150?u=client';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surfaceVariant,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  authProvider.userRole == 'worker' ? Icons.work : Icons.person,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  authProvider.userRole?.toUpperCase() ?? 'CLIENT',
                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustTierCard(bool isWorker) {
    final status = isWorker ? (_workerData?.verificationStatus ?? VerificationStatus.notStarted) : VerificationStatus.verified;
    String label = 'Standard';
    Color color = AppColors.onSurfaceVariant;

    if (status == VerificationStatus.verified) {
      label = 'Verified';
      color = AppColors.primary;
    } else if (status == VerificationStatus.pending) {
      label = 'Under Review';
      color = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.shield_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRUST TIER', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
                Row(
                  children: [
                    Flexible(
                      child: Text(label, style: AppTypography.headlineMedium.copyWith(fontSize: 18, color: color, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    ),
                    if (status == VerificationStatus.verified)
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
    final rating = isWorker ? (_workerData?.rating ?? 0.0) : 5.0;
    final jobs = isWorker ? (_workerData?.completedJobsCount ?? 0) : 12;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(rating.toString(), 'Rating', Icons.star, Colors.amber),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(jobs.toString(), isWorker ? 'Jobs Done' : 'Bookings', Icons.task_alt, AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOptions(bool isWorker) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
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

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
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
          const Divider(height: 1),
          _buildOptionRow(
            icon: Icons.help_outline,
            title: 'Help / FAQ',
            onTap: () => Navigator.pushNamed(context, AppRouter.help),
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

  Widget _buildOptionRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
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
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.outlineVariant),
      onTap: onTap,
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    String label = 'NOT STARTED';
    Color color = AppColors.onSurfaceVariant;

    switch (status) {
      case VerificationStatus.verified:
        label = 'ACTIVE';
        color = AppColors.primary;
        break;
      case VerificationStatus.pending:
        label = 'PENDING';
        color = Colors.amber;
        break;
      case VerificationStatus.rejected:
        label = 'REJECTED';
        color = AppColors.error;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
        label: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 16)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.error.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
