import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../services/service_locator.dart';
import '../../data/models/worker_model.dart';
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
    final worker = await workerRepository.getWorkerById(widget.workerId);
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_worker == null) {
      return const Scaffold(body: Center(child: Text('Worker not found')));
    }

    final worker = _worker!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. Standard Header
          const AppHeader(title: 'HanapBuhay'),

          // 2. Scrollable Content
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
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.onSurfaceVariant,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      unselectedLabelStyle: AppTypography.bodyMedium,
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'Portfolio'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(worker),
                  _buildPortfolioTab(worker),
                  _buildReviewsTab(worker),
                ],
              ),
            ),
          ),
          
          // 3. Sticky Bottom Bar
          _buildBottomBar(worker),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Worker worker) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceContainerLow,
            AppColors.background,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Profile Image with Gradient Ring
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
                      AppColors.primaryContainer,
                      AppColors.secondaryContainer,
                    ],
                  ),
                ),
              ),
              CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(worker.avatarUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name and Verified Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                worker.name,
                style: AppTypography.headlineLarge.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              if (worker.isVerified)
                const Icon(Icons.verified, color: AppColors.primary, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          
          // Trust Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Verified Professional',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                worker.rating.toString(),
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                ' (${worker.reviewCount} reviews)',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(Worker worker) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceContainerHigh),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
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
                    const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Professional Summary', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  worker.bio,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Services Offered
          Text('Services Offered', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
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
          
          // Availability Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Responds in ~${worker.responseTime}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isAction ? AppColors.surfaceContainer : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isAction ? AppColors.outlineVariant : AppColors.primary.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isAction ? AppColors.onSurfaceVariant : AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool isAvailable) {
    if (!isAvailable) {
      return Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle));
    }
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      // Pulse effect could be added here
    );
  }

  Widget _buildPortfolioTab(Worker worker) {
    // TODO: Portfolio management is a Section 2 feature. This is a client-facing placeholder.
    if (worker.portfolioImages.isEmpty) {
      return _buildEmptyTab('No portfolio items yet', Icons.image_outlined);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4/3,
      ),
      itemCount: worker.portfolioImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(worker.portfolioImages[index], fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildReviewsTab(Worker worker) {
    // TODO: Submission flow is 1.8. This is a view-only placeholder.
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
                      Text(review.reviewerName, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star, 
                          size: 14, 
                          color: i < review.rating ? Colors.amber : AppColors.surfaceContainerHigh,
                        )),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${review.date.day}/${review.date.month}/${review.date.year}',
                  style: AppTypography.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyTab(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Worker worker) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Starting from', style: AppTypography.bodySmall),
                RichText(
                  text: TextSpan(
                    style: AppTypography.headlineMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: '₱${worker.hourlyRate.toInt()}'),
                      TextSpan(text: ' / hr', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: () {
              context.push('${AppRouter.chatThread}/c1'); // Mock conversation ID
            },
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: 'Book Now',
              showArrow: true,
              onPressed: () {
                context.push('${AppRouter.sendBookingRequest}/${worker.id}');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
