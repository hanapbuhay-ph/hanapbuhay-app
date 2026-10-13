import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/trust_tier.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/cards/job_post_card.dart';

class WorkerProfileViewScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileViewScreen({super.key, required this.workerId});

  @override
  State<WorkerProfileViewScreen> createState() =>
      _WorkerProfileViewScreenState();
}

class _WorkerProfileViewScreenState extends State<WorkerProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Worker? _worker;
  bool _isLoading = true;
  bool _expandServices = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchWorker();
  }

  Future<void> _fetchWorker() async {
    final worker = await context.read<WorkerProvider>().getWorkerById(
      widget.workerId,
    );
    if (mounted) {
      setState(() {
        _worker = worker;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_worker == null) {
      return const Scaffold(body: Center(child: Text('Worker not found')));
    }

    final worker = _worker!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Profile'),

          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _buildProfileHeader(worker)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      indicatorWeight: 3,
                      labelStyle: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: AppTypography.bodyMedium,
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'Posts'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                    colorScheme: colorScheme,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(worker),
                  _buildPostsTab(worker),
                  _buildReviewsTab(worker),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trustInfo = worker.trustTier.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            colorScheme.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(worker.avatarUrl),
                ),
              ),
              if (worker.isOnline)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            worker.name,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: trustInfo.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trustInfo.icon, color: trustInfo.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  trustInfo.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: trustInfo.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _availabilityColor(worker.availabilityStatus)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _availabilityIcon(worker.availabilityStatus),
                  color: _availabilityColor(worker.availabilityStatus),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  _availabilityLabel(worker.availabilityStatus),
                  style: AppTypography.labelSmall.copyWith(
                    color: _availabilityColor(worker.availabilityStatus),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 17, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '${worker.rating} · ${worker.reviewCount} reviews · ${worker.completedJobsCount} jobs',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 17,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${worker.barangay} · ${_formatDistance(worker.distance)}',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDistance(String distance) {
    final normalized = distance.replaceFirst(RegExp(r'^~+'), '');
    if (normalized.toLowerCase().startsWith('distance unavailable')) {
      return normalized;
    }
    return '~$normalized';
  }

  Color _availabilityColor(WorkerAvailability status) {
    switch (status) {
      case WorkerAvailability.available:
        return Colors.green;
      case WorkerAvailability.busy:
        return Colors.orange;
      case WorkerAvailability.offline:
        return Colors.grey;
    }
  }

  IconData _availabilityIcon(WorkerAvailability status) {
    switch (status) {
      case WorkerAvailability.available:
        return Icons.check_circle;
      case WorkerAvailability.busy:
        return Icons.schedule;
      case WorkerAvailability.offline:
        return Icons.do_not_disturb_on;
    }
  }

  String _availabilityLabel(WorkerAvailability status) {
    switch (status) {
      case WorkerAvailability.available:
        return 'Available';
      case WorkerAvailability.busy:
        return 'Busy';
      case WorkerAvailability.offline:
        return 'Offline';
    }
  }

  Widget _buildAboutTab(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Professional Summary',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  worker.bio,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Services Offered',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              ...worker.services
                  .take(_expandServices ? worker.services.length : 3)
                  .map((s) => _buildServiceChip(s)),
              if (worker.services.length > 3 && !_expandServices)
                GestureDetector(
                  onTap: () => setState(() => _expandServices = true),
                  child: _buildServiceChip(
                    '+${worker.services.length - 3} more',
                    isAction: true,
                  ),
                ),
            ],
          ),
          if (worker.portfolioImages.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Past Work',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: worker.portfolioImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  worker.portfolioImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                _buildStatusDot(worker.isAvailable),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.isAvailable
                            ? 'Currently Available'
                            : 'Currently Unavailable',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Responds in ~${worker.responseTime}',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label, {bool isAction = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isAction
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isAction
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isAction ? colorScheme.onSurfaceVariant : colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool isAvailable) {
    if (!isAvailable) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPostsTab(Worker worker) {
    if (worker.jobPosts.isEmpty) {
      return _buildEmptyTab('No active posts yet', Icons.work_outline);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: worker.jobPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return JobPostCard(
          listing: JobPostListing(worker: worker, post: worker.jobPosts[index]),
        );
      },
    );
  }

  Widget _buildReviewsTab(Worker worker) {
    final colorScheme = Theme.of(context).colorScheme;
    if (worker.reviews.isEmpty) {
      return _buildEmptyTab('No reviews yet', Icons.rate_review_outlined);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: worker.reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final review = worker.reviews[index];
        final bookingId = review.bookingId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(review.reviewerAvatar),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            size: 14,
                            color: i < review.rating
                                ? Colors.amber
                                : colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${review.date.day}/${review.date.month}/${review.date.year}',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (bookingId != null && bookingId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Re: Booking #${Booking.formatBookingCode(bookingId, review.date)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyTab(String message, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.colorScheme});

  final TabBar _tabBar;
  final ColorScheme colorScheme;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: colorScheme.surface.withValues(alpha: 0.95),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
