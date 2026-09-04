import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/barangay_model.dart';
import '../../data/models/trust_tier.dart';
import '../../widgets/buttons/primary_button.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late Future<List<JobPostListing>> _filteredWorkersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final workerProvider = context.read<WorkerProvider>();
    final authProvider = context.read<AuthProvider>();
    _filteredWorkersFuture = workerProvider.getFilteredWorkers(userBarangayName: authProvider.userBarangay);
  }

  @override
  void dispose() {
    super.dispose();
  }


  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
        children: [
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
                    const SizedBox(height: 16),

                    // Quick Filters
                    _buildQuickFilters(),
                    const SizedBox(height: 16),

                    // Feed header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discover Workers', style: AppTypography.headlineMedium.copyWith(fontSize: 20)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vertical feed
                    _buildFeedSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
    );
  }

  // Header owned by TabShell

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workerProvider = context.watch<WorkerProvider>();
    final filterCount = workerProvider.activeAdvancedFilterCount;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.browseCategory),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: Text(
                'Search workers...',
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => _showAdvancedFilters(context),
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
                          style: TextStyle(color: colorScheme.onError, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(JobPostListing listing) {
    final colorScheme = Theme.of(context).colorScheme;
    final worker = listing.worker;
    final post = listing.post;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '${AppRouter.workerProfile}/${worker.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + trust badge
            Row(
              children: [
                CircleAvatar(radius: 26, backgroundImage: NetworkImage(worker.avatarUrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        post.category,
                        style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _buildTrustBadge(worker, colorScheme),
              ],
            ),
            const SizedBox(height: 10),
            // Post title
            Text(
              post.title,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Description preview
            Text(
              post.description,
              style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Bottom row: location + rate + availability dot
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 13, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(
                  worker.distance,
                  style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'From ₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: worker.isAvailable ? colorScheme.primary : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(Worker worker, ColorScheme colorScheme) {
    final tier = worker.trustTier;
    final Color color;
    final String label;
    final IconData icon;

    switch (tier) {
      case TrustTier.trusted:
        color = Colors.blue;
        label = 'Trusted';
        icon = Icons.star;
        break;
      case TrustTier.verified:
        color = colorScheme.primary;
        label = 'Verified';
        icon = Icons.shield;
        break;
      default:
        color = Colors.orange;
        label = 'Unverified';
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
              color: colorScheme.shadow.withValues(alpha: 0.06),
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final workerProvider = context.watch<WorkerProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: ['All', 'Verified ✓', 'Unverified'].map((label) {
          final filterKey = label.replaceAll(' ✓', '');
          final isSelected = workerProvider.quickFilter == filterKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  workerProvider.setQuickFilter(filterKey);
                  _loadData();
                }
              },
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.2),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<JobPostListing>>(
      future: _filteredWorkersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
          );
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(Icons.search_off, size: 56, color: colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text('No workers found', style: AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or check back later.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: listings.length,
          itemBuilder: (context, index) => _buildWorkerCard(listings[index]),
        );
      },
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
