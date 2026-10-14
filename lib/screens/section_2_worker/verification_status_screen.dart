import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../data/models/trust_tier.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  // GET /api/worker/verification/status
  // Response: { verification_status, trust_tier, remarks (NOT verification_remarks), documents[] }
  late Future<Map<String, dynamic>?> _statusFuture;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() {
    _statusFuture = context.read<WorkerProvider>().getVerificationStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                const AppHeader(title: 'Verification Status'),
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return Column(
              children: [
                const AppHeader(title: 'Verification Status'),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Unable to load verification status.'),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => setState(() => _loadStatus()),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data;
          final status =
              data?['verification_status']?.toString() ?? 'not_started';
          final trustTier = _parseTrustTier(data?['trust_tier']?.toString());
          final remarks = data?['remarks']?.toString(); // backend key is "remarks", not "verification_remarks"
          final documents = data?['documents'] as List<dynamic>? ?? [];

          return Column(
            children: [
              const AppHeader(title: 'Verification Status'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(() => _loadStatus()),
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildStatusContent(
                      status,
                      trustTier,
                      remarks,
                      documents,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TrustTier? _parseTrustTier(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'trusted':
        return TrustTier.trusted;
      case 'verified':
        return TrustTier.verified;
      case 'flagged':
        return TrustTier.flagged;
      case 'revoked':
        return TrustTier.revoked;
      default:
        return null;
    }
  }

  Widget _buildStatusContent(
    String status,
    TrustTier? trustTier,
    String? remarks,
    List<dynamic> documents,
  ) {
    switch (status) {
      case 'approved':
        return _buildApprovedState(documents, trustTier);
      case 'pending':
        return _buildPendingState(documents);
      case 'rejected':
        return _buildRejectedState(remarks, documents);
      case 'resubmission_required':
        return _buildResubmissionState(remarks, documents);
      default:
        // not_started / unknown
        return _buildNotStartedState();
    }
  }

  /// Builds the per-document status list from the real API documents[] array.
  /// Falls back to a static list when documents are empty (e.g., not_started).
  Widget _buildDocumentStatusList(List<dynamic> documents) {
    final colorScheme = Theme.of(context).colorScheme;

    final staticLabels = {
      'government_id_front': 'Government ID (Front)',
      'government_id_back': 'Government ID (Back)',
      'barangay_certificate': 'Barangay Certificate',
      'selfie_with_id': 'Selfie with ID',
      'skill_certificate': 'Skill Certificate',
    };

    // If we have real document data, render from it
    final documentStatuses = <String, String>{
      for (final d in documents)
        if (d is Map && d['type'] != null)
          d['type'].toString(): d['status']?.toString() ?? 'pending',
    };
    final rows = staticLabels.entries
        .map(
          (entry) => {
            'label': entry.value,
            'status':
                documentStatuses[entry.key] ??
                (entry.key == 'government_id_front'
                    ? documentStatuses['government_id']
                    : null) ??
                'not_started',
          },
        )
        .toList();

    IconData iconFor(String s) {
      switch (s) {
        case 'approved':
          return Icons.check_circle;
        case 'rejected':
          return Icons.cancel;
        case 'pending':
          return Icons.schedule;
        case 'resubmission_required':
          return Icons.edit_note;
        default:
          return Icons.remove;
      }
    }

    Color colorFor(String s) {
      switch (s) {
        case 'approved':
          return colorScheme.primary;
        case 'rejected':
          return colorScheme.error;
        case 'pending':
          return Colors.amber;
        case 'resubmission_required':
          return Colors.orange;
        default:
          return colorScheme.onSurfaceVariant;
      }
    }

    String labelFor(String s) {
      switch (s) {
        case 'approved':
          return 'Approved';
        case 'rejected':
          return 'Rejected';
        case 'pending':
          return 'Under Review';
        case 'resubmission_required':
          return 'Needs Update';
        default:
          return 'Not submitted';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final s = row['status']?.toString() ?? 'not_started';
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row['label']?.toString() ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(iconFor(s), color: colorFor(s), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      labelFor(s),
                      style: AppTypography.labelSmall.copyWith(
                        color: colorFor(s),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotStartedState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.description_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Not Yet Verified',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Submit your documents to get barangay-verified and rank higher in client searches.',
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildDocumentStatusList([]),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Submit Documents Now',
          onPressed: () =>
              Navigator.pushNamed(context, AppRouter.verificationDocuments),
        ),
      ],
    );
  }

  Widget _buildPendingState(List<dynamic> documents) {
    final colorScheme = Theme.of(context).colorScheme;
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
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your verification documents have been received and are currently being reviewed by our team. This usually takes 24–48 hours.',
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        LinearProgressIndicator(
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 32),
        _buildDocumentStatusList(documents),
        const SizedBox(height: 32),
        _buildSupportButton(),
      ],
    );
  }

  Widget _buildApprovedState(List<dynamic> documents, TrustTier? trustTier) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.read<AuthProvider>();
    final name = authProvider.userName ?? 'Worker';
    final avatarUrl = authProvider.userAvatar;
    final trustInfo = (trustTier ?? TrustTier.verified).info;

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
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Congratulations! Your identity has been verified. You now have full access to worker features.',
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildDocumentStatusList(documents),
        const SizedBox(height: 32),
        // Badge Preview Card — uses real user data from AuthProvider
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
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
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: trustInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trustInfo.icon, size: 14, color: trustInfo.color),
                    const SizedBox(width: 6),
                    Text(
                      'Trust Tier: ${trustInfo.label}',
                      style: AppTypography.labelSmall.copyWith(
                        color: trustInfo.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Go to Dashboard',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRouter.workerHome),
        ),
      ],
    );
  }

  Widget _buildRejectedState(String? remarks, List<dynamic> documents) {
    final colorScheme = Theme.of(context).colorScheme;
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
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "We couldn't verify your identity with the provided documents. Please review the reason below and try again.",
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildDocumentStatusList(documents),
        const SizedBox(height: 32),
        // Rejection remarks card — "remarks" key from real backend (not "verification_remarks")
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
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                remarks?.isNotEmpty == true ? remarks! : 'No details provided.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Resubmit Documents',
          onPressed: () =>
              Navigator.pushNamed(context, AppRouter.verificationDocuments),
        ),
        const SizedBox(height: 16),
        _buildSupportButton(),
      ],
    );
  }

  Widget _buildResubmissionState(String? remarks, List<dynamic> documents) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(Icons.edit_note, size: 80, color: Colors.orange.shade700),
        const SizedBox(height: 24),
        Text(
          'Changes Requested',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please review the administrator remarks and resubmit your documents.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (remarks?.isNotEmpty == true)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              remarks!,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        const SizedBox(height: 24),
        _buildDocumentStatusList(documents),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Resubmit Documents',
          onPressed: () =>
              Navigator.pushNamed(context, AppRouter.verificationDocuments),
        ),
      ],
    );
  }

  Widget _buildSupportButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, '${AppRouter.chatThread}/support');
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Contact Support',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
