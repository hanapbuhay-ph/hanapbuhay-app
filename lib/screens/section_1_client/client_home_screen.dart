import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/client_bottom_nav.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late Future<List<Worker>> _topRatedFuture;
  late Future<List<Worker>> _recentlyViewedFuture;
  late Future<List<ServiceCategory>> _categoriesFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final workerProvider = context.read<WorkerProvider>();
    _categoriesFuture = workerProvider.getCategories();
    _topRatedFuture = workerProvider.getTopRatedWorkers();
    _recentlyViewedFuture = workerProvider.getRecentlyViewedWorkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName ?? authProvider.userEmail?.split('@').first ?? 'User';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // 1. Sticky Header
          _buildHeader(userName),

          // 2. Scrollable Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() => _loadData());
              },
              color: colorScheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildSearchBar(),
                    ),
                    const SizedBox(height: 32),

                    // Categories
                    _buildCategoriesSection(),
                    const SizedBox(height: 32),

                    // Top Rated
                    _buildTopRatedSection(),
                    const SizedBox(height: 32),

                    // Recently Viewed
                    _buildRecentlyViewedSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeader(String name) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.read<AuthProvider>();
    final avatar = authProvider.userAvatar;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: colorScheme.onSurfaceVariant),
              onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(avatar ?? 'https://i.pravatar.cc/150?u=client'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(), style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
                  Text(
                    name,
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none_outlined, color: colorScheme.onSurface),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.notificationCenter);
                  },
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: StreamBuilder<int>(
                    stream: context.read<NotificationProvider>().getUnreadCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 1.5),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pushNamed(context, '${AppRouter.workerSearch}?query=$value');
                }
              },
              decoration: InputDecoration(
                hintText: 'Search for services (e.g. plumbing)',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '${AppRouter.workerSearch}?filter=true');
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune, color: colorScheme.onPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Categories', style: AppTypography.headlineMedium.copyWith(fontSize: 20)),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<ServiceCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.asMap().entries.map((entry) {
                  final category = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(category.label),
                      labelStyle: AppTypography.labelLarge.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      onSelected: (_) {
                        Navigator.pushNamed(context, '${AppRouter.workerSearch}?category=${category.label}');
                      },
                      avatar: Icon(
                        category.icon,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide.none),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopRatedSection() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Rated Near You', style: AppTypography.headlineMedium.copyWith(fontSize: 20)),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.workerSearch);
                },
                child: Text('See all', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: FutureBuilder<List<Worker>>(
            future: _topRatedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
              }
              final workers = snapshot.data ?? [];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: workers.length,
                itemBuilder: (context, index) => _buildWorkerCard(workers[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '${AppRouter.workerProfile}/${worker.id}');
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(radius: 28, backgroundImage: NetworkImage(worker.avatarUrl)),
                    if (worker.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                          child: Icon(Icons.check, color: colorScheme.onPrimary, size: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                      Text(worker.specialty, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withValues(alpha: 0.2), 
                    borderRadius: BorderRadius.circular(6)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(worker.rating.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(worker.distance, style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: AppTypography.headlineMedium.copyWith(color: colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: '₱${worker.hourlyRate.toInt()}'),
                      TextSpan(text: '/hr', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recently Viewed', style: AppTypography.headlineMedium.copyWith(fontSize: 20)),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.workerSearch);
                },
                child: Text('See all', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Worker>>(
          future: _recentlyViewedFuture,
          builder: (context, snapshot) {
            final workers = snapshot.data ?? [];
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: workers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildRecentWorkerRow(workers[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentWorkerRow(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '${AppRouter.workerProfile}/${worker.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(worker.avatarUrl, width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(worker.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(worker.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Text(worker.specialty, style: AppTypography.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: worker.tags.map((tag) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.surfaceVariant.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
