import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/trust_tier.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/barangay_model.dart';
import '../../widgets/navigation/client_bottom_nav.dart';
import '../../widgets/navigation/app_back_button.dart';
import '../../widgets/buttons/primary_button.dart';

class WorkerSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final bool showFilterOnInit;

  const WorkerSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
    this.showFilterOnInit = false,
  });

  @override
  State<WorkerSearchScreen> createState() => _WorkerSearchScreenState();
}

class _WorkerSearchScreenState extends State<WorkerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<JobPostListing> _filteredListings = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _selectedCategory = widget.initialCategory;
    
    if (_selectedCategory != null) {
      // Sync initial category with provider
      Future.delayed(Duration.zero, () {
        if (mounted) {
          context.read<WorkerProvider>().setAdvancedFilters(categories: [_selectedCategory!]);
          _fetchWorkers();
        }
      });
    } else {
      _fetchWorkers();
    }
    
    if (widget.showFilterOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFilterSheet();
      });
    }
  }

  Future<void> _fetchWorkers() async {
    setState(() => _isLoading = true);
    final workerProvider = context.read<WorkerProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // Applying current search query and filters through provider
    _filteredListings = await workerProvider.getFilteredWorkers(userBarangayName: authProvider.userBarangay);
    
    // Search query filter (local)
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      _filteredListings = _filteredListings.where((listing) {
        return listing.worker.name.toLowerCase().contains(query) ||
               listing.post.title.toLowerCase().contains(query) ||
               listing.post.category.toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _isLoading = false);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AdvancedFilterBottomSheet(),
    ).then((_) => _fetchWorkers());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workerProvider = context.watch<WorkerProvider>();
    final filterCount = workerProvider.activeAdvancedFilterCount;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          _buildHeader(filterCount),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : _filteredListings.isEmpty 
                  ? _buildEmptyState()
                  : _buildResultsList(),
          ),
        ],
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: -1),
    );
  }

  Widget _buildHeader(int filterCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            const AppBackButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _fetchWorkers(),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search for workers...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.search, color: colorScheme.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune, color: colorScheme.onPrimary),
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
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredListings.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Listings', style: AppTypography.headlineMedium.copyWith(color: theme.colorScheme.onSurface)),
                Text(
                  'Showing ${_filteredListings.length} results',
                  style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        return _buildWorkerCard(_filteredListings[index - 1]);
      },
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
        margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 32, backgroundImage: NetworkImage(worker.avatarUrl)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(worker.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18, color: colorScheme.onSurface)),
                          const SizedBox(width: 4),
                          Icon(worker.trustTier.info.icon, color: worker.trustTier.info.color, size: 18),
                        ],
                      ),
                      Text(post.title, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(worker.rating.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface)),
                          Text(' • ${worker.reviewCount} reviews', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post.category, 
                    style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700)
                  ),
                ),
                ...worker.tags.take(2).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag, 
                    style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w700)
                  ),
                )).toList(),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(worker.distance, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: AppTypography.headlineMedium.copyWith(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'From ₱${post.startingRate.toInt()}'),
                      TextSpan(text: post.rateType.shortLabel, style: AppTypography.bodySmall.copyWith(fontSize: 12, color: colorScheme.onSurfaceVariant)),
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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final workerProvider = context.read<WorkerProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off, size: 60, color: theme.colorScheme.outlineVariant),
            ),
            const SizedBox(height: 24),
            Text('No workers found', style: AppTypography.headlineMedium.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find anyone matching your current filters. Try adjusting your search criteria.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  workerProvider.resetFilters();
                });
                _fetchWorkers();
              },
              child: Text('Clear Filters', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
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
