import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/trust_tier.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/barangay_model.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/navigation/client_bottom_nav.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late Future<List<JobPostListing>> _filteredWorkersFuture;
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
    final authProvider = context.read<AuthProvider>();
    
    _categoriesFuture = workerProvider.getCategories();
    _filteredWorkersFuture = workerProvider.getFilteredWorkers(userBarangayName: authProvider.userBarangay);
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

                    // Quick Filters
                    _buildQuickFilters(),
                    const SizedBox(height: 24),

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
    final workerProvider = context.watch<WorkerProvider>();
    final filterCount = workerProvider.activeAdvancedFilterCount;

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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    _showAdvancedFilters(context);
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
                if (filterCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: Text(
                        filterCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
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
          child: FutureBuilder<List<JobPostListing>>(
            future: _filteredWorkersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
              }
              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return Center(child: Text('No workers match filters', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: listings.length,
                itemBuilder: (context, index) => _buildWorkerCard(listings[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(JobPostListing listing) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final worker = listing.worker;
    final post = listing.post;

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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: worker.trustTier.info.color, shape: BoxShape.circle),
                        child: Icon(worker.trustTier.info.icon, color: Colors.white, size: 10),
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
                      Text(post.category, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      TextSpan(text: 'From ₱${post.startingRate.toInt()}'),
                      TextSpan(text: post.rateType.shortLabel, style: AppTypography.bodySmall.copyWith(fontSize: 10)),
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

  Widget _buildQuickFilters() {
    final workerProvider = context.watch<WorkerProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: ['All', 'Verified', 'Unverified'].map((label) {
          final isSelected = workerProvider.quickFilter == label;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  workerProvider.setQuickFilter(label);
                  _loadData();
                }
              },
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.2),
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AdvancedFilterBottomSheet(),
    ).then((_) => _loadData());
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

class _AdvancedFilterBottomSheet extends StatefulWidget {
  const _AdvancedFilterBottomSheet();

  @override
  State<_AdvancedFilterBottomSheet> createState() => _AdvancedFilterBottomSheetState();
}

class _AdvancedFilterBottomSheetState extends State<_AdvancedFilterBottomSheet> {
  late List<String> _selectedCategories;
  String? _selectedBarangay;
  late List<RateType> _selectedRateTypes;
  late bool _onlyAvailable;

  @override
  void initState() {
    super.initState();
    final workerProvider = context.read<WorkerProvider>();
    _selectedCategories = List.from(workerProvider.selectedCategories);
    _selectedBarangay = workerProvider.selectedBarangay;
    _selectedRateTypes = List.from(workerProvider.selectedRateTypes);
    _onlyAvailable = workerProvider.onlyAvailableNow;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workerProvider = context.read<WorkerProvider>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Advanced Filters', style: AppTypography.headlineMedium.copyWith(fontSize: 22)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategories = [];
                    _selectedBarangay = null;
                    _selectedRateTypes = [];
                    _onlyAvailable = false;
                  });
                },
                child: Text('Reset', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text('Service Category', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<ServiceCategory>>(
                    future: workerProvider.getCategories(),
                    builder: (context, snapshot) {
                      final categories = (snapshot.data ?? []).map((c) => c.label).toList();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = _selectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedCategories.add(cat);
                                } else {
                                  _selectedCategories.remove(cat);
                                }
                              });
                            },
                            selectedColor: colorScheme.primary,
                            labelStyle: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                            backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.2),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text('Barangay', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedBarangay,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    hint: const Text('All Barangays'),
                    items: Barangay.trinidadBarangays.map((b) => DropdownMenuItem(
                      value: b.name,
                      child: Text(b.name),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedBarangay = val),
                    dropdownColor: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 32),
                  Text('Rate Type', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RateType.values.map((type) {
                      final isSelected = _selectedRateTypes.contains(type);
                      return FilterChip(
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedRateTypes.add(type);
                            } else {
                              _selectedRateTypes.remove(type);
                            }
                          });
                        },
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                        backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.2),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Now', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text('Show only workers ready to work', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      Switch(
                        value: _onlyAvailable,
                        onChanged: (val) => setState(() => _onlyAvailable = val),
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    label: 'Apply Filters',
                    onPressed: () {
                      workerProvider.setAdvancedFilters(
                        categories: _selectedCategories,
                        barangay: _selectedBarangay,
                        rateTypes: _selectedRateTypes,
                        onlyAvailable: _onlyAvailable,
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
