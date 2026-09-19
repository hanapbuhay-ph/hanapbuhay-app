import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/report_provider.dart';
import '../../data/models/report_model.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/status/status_badge.dart';
import '../../widgets/navigation/app_header.dart';

class ReportStatusScreen extends StatefulWidget {
  const ReportStatusScreen({super.key});

  @override
  State<ReportStatusScreen> createState() => _ReportStatusScreenState();
}

class _ReportStatusScreenState extends State<ReportStatusScreen> {
  late Future<List<Report>> _reportsFuture;
  final Set<String> _expandedReportIds = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = context.read<ReportProvider>().getReports();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedReportIds.contains(id)) {
        _expandedReportIds.remove(id);
      } else {
        _expandedReportIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Report Status'),
          Expanded(
            child: FutureBuilder<List<Report>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                }

                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Reports', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        'Track the status of your recent issue reports and dispute resolutions.',
                        style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                      ...reports.map((report) => _buildReportCard(report)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = _expandedReportIds.contains(report.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (Trigger)
          InkWell(
            onTap: () => _toggleExpand(report.id),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filed: ${AppFormatters.date(report.createdAt)}',
                        style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      _buildStatusBadge(report.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${report.reasonLabel} - ${report.description.split('.').first}',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TAP TO VIEW DETAILS',
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: isExpanded ? 0.5 : 0,
                        child: Icon(Icons.expand_more, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded)
            Container(
              color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Original Report', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _buildReporter(report),
                  const SizedBox(height: 20),
                  _buildReportMeta(report),
                  const SizedBox(height: 20),
                  Text(
                    report.description,
                    style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  
                  if (report.adminRemarks != null || report.resolutionAction != null) ...[
                    _buildAdminDecision(report),
                    const SizedBox(height: 24),
                  ],

                  if (report.followUpNotes.isNotEmpty) ...[
                    Text('Your Notes', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...report.followUpNotes.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• ${n.text}', style: AppTypography.bodySmall),
                    )),
                    const SizedBox(height: 16),
                  ],

                  if (report.photoPaths.isNotEmpty) ...[
                    _buildEvidencePhotos(report.photoPaths),
                    const SizedBox(height: 8),
                  ],

                  // "Add Note" button intentionally removed:
                  // POST /api/reports/{id}/notes does not exist in the backend.
                  // ApiReportRepository.addReportNote() throws UnimplementedError.
                  // Documented in HANDOFF.md as a missing endpoint blocker.
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ReportStatus.pending:
      case ReportStatus.underReview:
        color = Colors.amber;
        label = 'Under Review';
        icon = Icons.pending_actions;
        break;
      case ReportStatus.resolved:
        color = colorScheme.primary;
        label = 'Resolved';
        icon = Icons.check_circle;
        break;
      case ReportStatus.dismissed:
        color = colorScheme.onSurfaceVariant;
        label = 'Dismissed';
        icon = Icons.cancel;
        break;
    }

    return StatusBadge(
      label: label,
      color: color,
      icon: icon,
    );
  }

  Widget _buildReporter(Report report) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = report.reporterName ?? 'Client';
    final photoPath = report.reporterPhotoPath ?? report.reporterPhotoUrl;
    final photoUrl = photoPath == null
        ? null
      : AppConstants.getPhotoUrl(photoPath);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
            child: photoUrl == null
                ? Icon(Icons.person_outline, color: colorScheme.onPrimaryContainer)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reported by', style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Icon(Icons.person_search_outlined, color: colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildReportMeta(Report report) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: Icon(Icons.flag_outlined, size: 16, color: colorScheme.primary),
          label: Text('Reason: ${report.reasonLabel}'),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: Icon(Icons.confirmation_number_outlined, size: 16, color: colorScheme.primary),
          label: Text('Booking #${report.bookingId}'),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildAdminDecision(Report report) {
    final colorScheme = Theme.of(context).colorScheme;
    final decision = report.resolutionAction?.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_outlined, size: 19, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('Admin Decision', style: AppTypography.labelLarge.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800)),
            ],
          ),
          if (decision != null) ...[
            const SizedBox(height: 10),
            Text('Action: ${decision[0].toUpperCase()}${decision.substring(1)}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
          if (report.adminRemarks != null) ...[
            const SizedBox(height: 8),
            Text(report.adminRemarks!, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5)),
          ],
          if (report.resolvedBy != null || report.resolvedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              '${report.resolvedBy == null ? '' : 'Reviewed by ${report.resolvedBy}'}${report.resolvedAt == null ? '' : ' on ${AppFormatters.date(report.resolvedAt!)}'}',
              style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidencePhotos(List<String> paths) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidence Photos',
          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: paths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final url = AppConstants.getPhotoUrl(paths[index]);
              return GestureDetector(
                onTap: () => _showFullScreenImage(url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant, size: 28),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(String url) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(32),
                    color: colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Image unavailable', style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 80, color: AppColors.outlineVariant),
            const SizedBox(height: 24),
            Text('No Reports Filed', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'You haven\'t submitted any issue reports yet. If you encounter any problems with a service, you can report it from the Bookings page.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

}

