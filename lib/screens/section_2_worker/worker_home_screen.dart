import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/info/compact_info_row.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/job_post_model.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  late Future<Worker?> _workerFuture;
  late Future<List<Booking>> _requestsFuture;
  WorkerAvailability _currentStatus = WorkerAvailability.available;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final workerProvider = context.read<WorkerProvider>();
    final bookingProvider = context.read<BookingProvider>();
    
    // For demo/mock, we assume worker ID 'w1'
    _workerFuture = workerProvider.getWorkerById(AppConstants.mockWorkerId);
    _requestsFuture = bookingProvider.getBookings().then(
      (list) => list.where((b) => b.status == BookingStatus.pending).toList()
    );
  }

  Future<void> _handleResponse(String bookingId, bool accept) async {
    final bookingProvider = context.read<BookingProvider>();
    final result = await bookingProvider.respondToBooking(bookingId: bookingId, accept: accept);
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: accept ? theme.colorScheme.primary : theme.colorScheme.error),
      );
      if (accept) Navigator.pushNamed(context, '${AppRouter.jobDetail}/$bookingId');
      setState(() => _loadData());
    }
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
                      Row(
                        children: [
                          const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=client')),
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
                      Text('Request Details', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _buildSheetDetailRow(colorScheme, Icons.calendar_today_outlined, 'Date & Time', '${AppFormatters.date(request.date)} • ${request.time}'),
                      const SizedBox(height: 14),
                          _buildSheetDetailRow(colorScheme, Icons.location_on_outlined, 'Location', '${AppConstants.municipalityName} (${request.barangay})'),
                      const SizedBox(height: 14),
                      _buildSheetDetailRow(colorScheme, Icons.build_outlined, 'Service', request.category),
                      if (request.notes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Client Notes', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
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

  Widget _buildSheetDetailRow(ColorScheme colorScheme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firstName = authProvider.userName?.split(' ').first ?? authProvider.userEmail?.split('@').first ?? 'Ricardo';
    final theme = Theme.of(context);

    return FutureBuilder<Worker?>(
        future: _workerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }
          final worker = snapshot.data;
          if (worker == null) return const Center(child: Text('Worker profile not found'));

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loadData());
                  },
                  color: theme.colorScheme.primary,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    child: ResponsiveContent(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        _buildGreeting(firstName),
                        const SizedBox(height: 24),
                        if (worker.verificationStatus != VerificationStatus.verified) ...[
                          _buildVerificationBanner(worker),
                          const SizedBox(height: 24),
                        ],
                        _buildAvailabilityCard(),
                        const SizedBox(height: 24),
                        _buildStatsRow(worker),
                        const SizedBox(height: 32),
                        _buildActivePostsSection(worker),
                        const SizedBox(height: 32),
                        _buildIncomingRequestsSection(),
                        const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      );
  }

  Widget _buildGreeting(String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hi, $name!', style: AppTypography.headlineMedium.copyWith(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text('Ready for a great day of work.', style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildVerificationBanner(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.verificationStatus == VerificationStatus.rejected 
                        ? 'Verification Rejected'
                        : 'Your account isn\'t verified yet', 
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      worker.verificationStatus == VerificationStatus.rejected
                        ? 'Please review the reason and try again.'
                        : 'Verified workers get more bookings.', 
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (worker.verificationStatus == VerificationStatus.notStarted) {
                  Navigator.pushNamed(context, AppRouter.verificationDocuments);
                } else {
                  Navigator.pushNamed(context, AppRouter.verificationStatus);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                worker.verificationStatus == VerificationStatus.notStarted 
                  ? 'Complete Verification' 
                  : 'Check Status', 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Status', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildStatusToggle(WorkerAvailability.available, 'Available', theme.colorScheme.primary),
                _buildStatusToggle(WorkerAvailability.busy, 'Busy', Colors.orange),
                _buildStatusToggle(WorkerAvailability.offline, 'Offline', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(WorkerAvailability status, String label, Color color) {
    final theme = Theme.of(context);
    final isSelected = _currentStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Worker worker) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.verified,
          label: 'Trust Tier',
          value: worker.isVerified ? 'Verified' : 'Unverified',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.star,
          label: 'Rating',
          value: worker.rating.toString(),
          color: Colors.amber,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.work,
          label: 'Jobs',
          value: '${worker.completedJobsCount} Done',
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePostsSection(Worker worker) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Active Posts', style: AppTypography.headlineMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.manageJobPosts),
              child: Text('Manage', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (worker.jobPosts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.post_add_outlined, size: 48, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text('No active posts yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRouter.createJobPost),
                  child: const Text('Create your first post'),
                ),
              ],
            ),
          )
        else
          ...worker.jobPosts.map((post) => _buildJobPostCard(post)),
      ],
    );
  }

  void _showPostOptions(JobPost post) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '${AppRouter.editJobPost}/${post.id}');
              },
            ),
            ListTile(
              leading: Icon(Icons.block_outlined, color: colorScheme.error),
              title: Text('Deactivate Post', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Deactivate Post'),
                    content: Text('Deactivate "${post.title}"? It will no longer be visible to clients.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post deactivated')),
                          );
                        },
                        child: Text('Deactivate', style: TextStyle(color: colorScheme.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildJobPostCard(JobPost post) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onLongPress: () => _showPostOptions(post),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.work_outline, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                Text(post.category, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  'From ₱${post.startingRate.toStringAsFixed(0)}${post.rateType.shortLabel}',
                  style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: post.isAvailable ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '${AppRouter.editJobPost}/${post.id}'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildIncomingRequestsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Incoming Requests', style: AppTypography.headlineMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.incomingRequests),
              child: Text('View All', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Booking>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              final theme = Theme.of(context);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 12),
                    Text('No pending requests', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              );
            }
            return Column(
              children: requests.map((req) => _buildRequestCard(req)).toList(),
            );
          }
        ),
      ],
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
              const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=client')),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Pending', style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 16),
          _buildHomeInfoRow(Icons.calendar_today_outlined, AppFormatters.relativeDate(request.date), '${AppFormatters.date(request.date)} • ${request.time}'),
          const SizedBox(height: 12),
          _buildHomeInfoRow(Icons.location_on_outlined, '${AppConstants.municipalityName} (${request.barangay})', '~1.5 km away'),
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

  Widget _buildHomeInfoRow(IconData icon, String label, String sublabel) {
    return CompactInfoRow(
      icon: icon,
      label: label,
      value: sublabel,
    );
  }

}

