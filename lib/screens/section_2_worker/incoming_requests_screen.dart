import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/status/status_badge.dart';
import '../../widgets/info/compact_info_row.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/info/detail_info_row.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  late Future<List<Booking>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _requestsFuture = context.read<BookingProvider>().getBookings().then(
          (list) => list.where((b) => b.status == BookingStatus.pending).toList(),
        );
  }

  Future<void> _handleResponse(String bookingId, bool accept) async {
    final bookingProvider = context.read<BookingProvider>();

    if (accept) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Accept this booking?'),
          content: const Text('The client will be notified and the job will appear in your schedule.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Accept', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    } else {
      final confirmed = await _showDeclineSheet(bookingId);
      if (confirmed != true) return;
    }

    final result = await bookingProvider.respondToBooking(bookingId: bookingId, accept: accept);

    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: accept ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      );
      if (accept) {
        Navigator.pushNamed(context, '${AppRouter.jobDetail}/$bookingId');
      }
      setState(() => _load());
    }
  }

  Future<bool?> _showDeclineSheet(String bookingId) {
    final colorScheme = Theme.of(context).colorScheme;
    final reasonController = TextEditingController();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Reason for declining', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Optional — helps us improve the platform.', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Schedule conflict, too far, etc.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Decline Request', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text('Incoming Requests', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Booking>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 72, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No pending requests', style: AppTypography.headlineMedium.copyWith(fontSize: 20, color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    'New booking requests will appear here.',
                    style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _load()),
            color: colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) => _buildRequestCard(requests[index]),
            ),
          );
        },
      ),
    );
  }

  void _showRequestDetail(Booking request) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          const CircleAvatar(radius: 28, backgroundImage: NetworkImage(AppConstants.mockClientAvatar)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client Name', style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(request.category, style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 20),

                      // Details
                      Text('Request Details', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                      const SizedBox(height: 16),
                      _buildDetailRow(colorScheme, Icons.calendar_today_outlined, 'Date & Time', '${AppFormatters.date(request.date)} • ${request.time}'),
                      const SizedBox(height: 14),
                          _buildDetailRow(colorScheme, Icons.location_on_outlined, 'Location', '${AppConstants.municipalityName} (${request.barangay})'),
                      const SizedBox(height: 14),
                      _buildDetailRow(colorScheme, Icons.build_outlined, 'Service', request.category),
                      if (request.notes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Client Notes', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.notes,
                            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleResponse(request.id, false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Decline', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleResponse(request.id, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(ColorScheme colorScheme, IconData icon, String label, String value) {
    return DetailInfoRow(
      icon: icon,
      label: label,
      value: value,
      iconColor: colorScheme.primary,
      labelColor: colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildRequestCard(Booking request) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, backgroundImage: NetworkImage(AppConstants.mockClientAvatar)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client Name', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(request.category, style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_outlined, AppFormatters.relativeDate(request.date), '${AppFormatters.date(request.date)} • ${request.time}'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, '${AppConstants.municipalityName} (${request.barangay})', '~1.5 km away'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showRequestDetail(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Review Request', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final colorScheme = Theme.of(context).colorScheme;
    return StatusBadge(
      label: 'Pending',
      color: colorScheme.primary,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String sublabel) {
    return CompactInfoRow(
      icon: icon,
      label: label,
      value: sublabel,
    );
  }

}

