import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/trust_tier.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

class WorkerProfileViewScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileViewScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<WorkerProfileViewScreen> createState() => _WorkerProfileViewScreenState();
}

class _WorkerProfileViewScreenState extends State<WorkerProfileViewScreen> with SingleTickerProviderStateMixin {
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
    final worker = await context.read<WorkerProvider>().getWorkerById(widget.workerId);
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
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    if (_worker == null) {
      return const Scaffold(body: Center(child: Text('Worker not found')));
    }

    final worker = _worker!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'HanapBuhay'),

          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(worker),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      indicatorWeight: 3,
                      labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
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
              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
              ),
              CircleAvatar(
                radius: 64,
                backgroundColor: colorScheme.surface,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(worker.avatarUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                worker.name,
                style: AppTypography.headlineLarge.copyWith(fontSize: 28, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
              ),
              const SizedBox(width: 8),
              Icon(worker.trustTier.info.icon, color: worker.trustTier.info.color, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: colorScheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Verified Professional',
                  style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            '⭐ ${worker.rating} · ${worker.reviewCount} reviews · ${worker.completedJobsCount} jobs',
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '📍 ${worker.barangay} · ~${worker.distance}',
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
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
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
                    Icon(Icons.person_outline, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Professional Summary', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  worker.bio,
                  style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text('Services Offered', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              ...worker.services.take(_expandServices ? worker.services.length : 3).map((s) => _buildServiceChip(s)),
              if (worker.services.length > 3 && !_expandServices)
                GestureDetector(
                  onTap: () => setState(() => _expandServices = true),
                  child: _buildServiceChip('+${worker.services.length - 3} more', isAction: true),
                ),
            ],
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
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
                        worker.isAvailable ? 'Currently Available' : 'Currently Unavailable',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                      Text(
                        'Responds in ~${worker.responseTime}',
                        style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
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
        color: isAction ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isAction ? colorScheme.outlineVariant.withValues(alpha: 0.5) : colorScheme.primary.withValues(alpha: 0.1)),
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
      return Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle));
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
    );
  }

  Widget _buildPostsTab(Worker worker) {
    final colorScheme = Theme.of(context).colorScheme;

    if (worker.jobPosts.isEmpty) {
      return _buildEmptyTab('No active posts yet', Icons.work_outline);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: worker.jobPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = worker.jobPosts[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.category,
                  style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                post.description,
                style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'From ₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                    style: AppTypography.labelLarge.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: post.isAvailable ? colorScheme.primary : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    post.isAvailable ? 'Available' : 'Unavailable',
                    style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Book This Service',
                onPressed: () => _handleBooking(worker),
              ),
            ],
          ),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(review.reviewerAvatar)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.reviewerName, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star, 
                          size: 14, 
                          color: i < review.rating ? Colors.amber : colorScheme.surfaceContainerHighest,
                        )),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${review.date.day}/${review.date.month}/${review.date.year}',
                  style: AppTypography.bodySmall.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Re: Booking #${Booking.formatBookingCode(review.id, review.date)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
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
          Text(message, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _handleBooking(Worker worker) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if worker is verified or trusted
    final bool isVerified = worker.trustTier == TrustTier.verified || worker.trustTier == TrustTier.trusted;

    if (!isVerified) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Not Yet Verified')),
            ],
          ),
          content: const Text(
            'This worker has not yet completed barangay document verification. '
            'HanapBuhay cannot fully guarantee their identity at this time.\n\n'
            'Do you want to proceed with the booking at your own discretion?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Find Verified Worker path
                context.read<WorkerProvider>().setQuickFilter('Verified');
                Navigator.pop(context, false); // Return to feed
              },
              child: Text(
                'Find Verified Worker',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book Anyway'),
            ),
          ],
        ),
      );

      if (proceed == false) {
        if (mounted) {
          // If they chose "Find Verified Worker", we already set the filter.
          // Now we just need to go back to the Home screen.
          Navigator.popUntil(context, (route) => route.settings.name == AppRouter.clientHome || route.isFirst);
        }
        return;
      }
      if (proceed == null) return; // Dismissed without choice
    }

    // Proceed to booking form
    if (mounted) {
      Navigator.pushNamed(context, '${AppRouter.sendBookingRequest}/${worker.id}');
    }
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
