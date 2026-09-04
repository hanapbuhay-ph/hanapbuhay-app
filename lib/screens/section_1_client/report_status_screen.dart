import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                    '${report.reason} - ${report.description.split('.').first}',
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
                  Text(
                    report.description,
                    style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  
                  if (report.adminRemarks != null) ...[
                    _buildAdminRemarks(report),
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

                  if (report.status == ReportStatus.underReview || report.status == ReportStatus.pending)
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => _showAddNoteDialog(report.id),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Add Note', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
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

  Widget _buildAdminRemarks(Report report) {
    final colorScheme = Theme.of(context).colorScheme;
    final isResolved = report.status == ReportStatus.resolved;
    final color = isResolved ? colorScheme.onSurfaceVariant : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isResolved ? Icons.task_alt : Icons.admin_panel_settings, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                isResolved ? 'Resolution Summary' : 'Admin Remarks',
                style: AppTypography.labelLarge.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.adminRemarks!,
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          if (report.updatedAt != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Updated: ${AppFormatters.date(report.updatedAt!)}',
                style: AppTypography.labelSmall.copyWith(fontSize: 9, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ],
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

  void _showAddNoteDialog(String reportId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add more details to your report...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final reportProvider = context.read<ReportProvider>();
              await reportProvider.addReportNote(reportId: reportId, note: controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                setState(() => _loadReports());
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

}

