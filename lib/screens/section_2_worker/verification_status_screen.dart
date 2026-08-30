import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  late Future<Worker?> _workerFuture;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  void _loadWorker() {
    // For demo, assume current worker is 'w1'
    _workerFuture = context.read<WorkerProvider>().getWorkerById('w1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFB), // Surface Cream
      body: FutureBuilder<Worker?>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final worker = snapshot.data;
          if (worker == null) return const Center(child: Text('Profile not found'));

          return Column(
            children: [
              const AppHeader(title: 'Verification Status'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  physics: const BouncingScrollPhysics(),
                  child: _buildStatusContent(worker),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusContent(Worker worker) {
    switch (worker.verificationStatus) {
      case VerificationStatus.pending:
        return _buildPendingState();
      case VerificationStatus.verified:
        return _buildApprovedState(worker);
      case VerificationStatus.rejected:
        return _buildRejectedState(worker);
      default:
        return const Center(child: Text('No verification in progress.'));
    }
  }

  Widget _buildPendingState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFDD80).withOpacity(0.3), // Amber
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule, size: 40, color: Color(0xFFCA8400)),
        ),
        const SizedBox(height: 24),
        Text(
          'Documents Under Review',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your verification documents have been received and are currently being reviewed by our team. This usually takes 24-48 hours.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        LinearProgressIndicator(
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCA8400)),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 48),
        _buildSupportButton(),
      ],
    );
  }

  Widget _buildApprovedState(Worker worker) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification Approved',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Congratulations! Your identity has been verified. You now have full access to worker features.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Badge Preview Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            children: [
              Text(
                'BADGE PREVIEW',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(worker.avatarUrl),
                    backgroundColor: Colors.white,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, color: Colors.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(worker.name, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Trust Tier: Verified',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          label: 'Go to Dashboard',
          onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.workerHome),
        ),
      ],
    );
  }

  Widget _buildRejectedState(Worker worker) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel, size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification Rejected',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We couldn\'t verify your identity with the provided documents. Please review the reason below and try again.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Rejection Reason Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.errorContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'REASON FOR REJECTION',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                worker.rejectionReason ?? 'No details provided.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          label: 'Resubmit Documents',
          onPressed: () => Navigator.pushNamed(context, AppRouter.verificationDocuments),
        ),
        const SizedBox(height: 16),
        _buildSupportButton(),
      ],
    );
  }

  Widget _buildSupportButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, '${AppRouter.chatThread}/c2');
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Contact Support', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
