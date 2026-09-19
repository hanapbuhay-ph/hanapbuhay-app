import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/repositories/worker_repository.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/barangay_model.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/cards/job_post_card.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late Future<FeedResponse> _filteredWorkersFuture;
  late Future<List<ServiceCategory>> _categoriesFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final workerProvider = context.read<WorkerProvider>();
    _filteredWorkersFuture = workerProvider.getFeed();
    _categoriesFuture = workerProvider.getCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firstName = authProvider.userName?.split(' ').first ?? authProvider.userEmail?.split('@').first ?? 'Client';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
        children: [
          Container(
            width: double.infinity,
            color: colorScheme.primary,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: _buildGreeting(firstName),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() => _loadData());
              },
              color: colorScheme.primary,
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                child: ResponsiveContent(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),

                    _buildCategorySection(),
                    const SizedBox(height: 24),

                    // Feed header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discover Workers',
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 20,
                            height: 1,
                          ),
                        ),
                      ],
                    ),

                    // Vertical feed
                    _buildFeedSection(),
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

  // Header owned by TabShell

  Widget _buildGreeting(String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, $name!',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready to find the right service for you.',
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (query) {
          final trimmedQuery = query.trim();
          if (trimmedQuery.isEmpty) return;
          Navigator.pushNamed(context, '${AppRouter.workerSearch}?query=${Uri.encodeQueryComponent(trimmedQuery)}');
        },
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search worker name or service...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: IconButton(
            tooltip: 'Search workers',
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pushNamed(context, '${AppRouter.workerSearch}?query=${Uri.encodeQueryComponent(query)}');
              }
            },
            icon: Icon(Icons.arrow_forward, color: colorScheme.primary),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<ServiceCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <ServiceCategory>[];
        if (snapshot.connectionState == ConnectionState.waiting && categories.isEmpty) {
          return const SizedBox(height: 88, child: Center(child: CircularProgressIndicator()));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Categories', style: AppTypography.headlineMedium.copyWith(fontSize: 20, height: 1)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRouter.browseCategory),
                  child: Text('View All', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.take(4).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(ServiceCategory category) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 108,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '${AppRouter.categoryResults}/${category.id}?name=${Uri.encodeComponent(category.label)}',
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, color: colorScheme.primary, size: 28),
              const SizedBox(height: 6),
              Text(category.label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<FeedResponse>(
      future: _filteredWorkersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }
        final listings = snapshot.data?.posts ?? [];
        if (listings.isEmpty) {
          return Column(
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
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          itemCount: listings.length,
          itemBuilder: (context, index) => JobPostCard(listing: listings[index]),
        );
      },
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
                      final categories = snapshot.data ?? [];
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = _selectedCategories.contains(cat.id);
                          return FilterChip(
                            label: Text(cat.label),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedCategories.add(cat.id);
                                } else {
                                  _selectedCategories.remove(cat.id);
                                }
                              });
                            },
                            selectedColor: colorScheme.primary,
                            labelStyle: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
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
                    initialValue: _selectedBarangay,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    hint: const Text('All Barangays'),
                    items: Barangay.trinidadBarangays.map((b) => DropdownMenuItem(
                      value: b.id,
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
                        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
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
                        activeThumbColor: colorScheme.primary,
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
