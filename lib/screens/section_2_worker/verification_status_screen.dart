import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    _workerFuture = context.read<WorkerProvider>().getWorkerById('w1');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: FutureBuilder<Worker?>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }
          final worker = snapshot.data;
          if (worker == null) return Center(child: Text('Profile not found', style: TextStyle(color: colorScheme.onSurface)));

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1), 
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule, size: 40, color: Colors.amber),
        ),
        const SizedBox(height: 24),
        Text(
          'Documents Under Review',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your verification documents have been received and are currently being reviewed by our team. This usually takes 24-48 hours.',
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        LinearProgressIndicator(
          backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 48),
        _buildSupportButton(),
      ],
    );
  }

  Widget _buildApprovedState(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, size: 40, color: colorScheme.primary),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification Approved',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Congratulations! Your identity has been verified. You now have full access to worker features.',
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Badge Preview Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Text(
                'BADGE PREVIEW',
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
                    backgroundColor: colorScheme.surfaceVariant,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                    child: Icon(Icons.verified, color: colorScheme.onPrimary, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(worker.name, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Trust Tier: Verified',
                      style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cancel, size: 40, color: colorScheme.error),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification Rejected',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We couldn\'t verify your identity with the provided documents. Please review the reason below and try again.',
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Rejection Reason Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'REASON FOR REJECTION',
                    style: AppTypography.labelSmall.copyWith(color: colorScheme.error, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                worker.rejectionReason ?? 'No details provided.',
                style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
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
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, '${AppRouter.chatThread}/c2');
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Contact Support', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
