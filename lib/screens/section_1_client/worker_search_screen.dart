import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
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
  List<Worker> _allWorkers = [];
  List<Worker> _filteredWorkers = [];
  bool _isLoading = true;

  // Filter States
  String? _selectedCategory;
  double _maxDistance = 20.0;
  double _minRating = 0.0;
  bool _verifiedOnly = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _selectedCategory = widget.initialCategory;
    _fetchWorkers();
    
    if (widget.showFilterOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFilterSheet();
      });
    }
  }

  Future<void> _fetchWorkers() async {
    setState(() => _isLoading = true);
    _allWorkers = await context.read<WorkerProvider>().getTopRatedWorkers();
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredWorkers = _allWorkers.where((worker) {
        final matchesQuery = _searchController.text.isEmpty ||
            worker.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            worker.specialty.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesCategory = _selectedCategory == null || 
            worker.specialty.toLowerCase().contains(_selectedCategory!.toLowerCase());
        
        final distance = double.tryParse(worker.distance.split(' ')[0]) ?? 0.0;
        final matchesDistance = distance <= _maxDistance;
        
        final matchesRating = worker.rating >= _minRating;
        final matchesVerified = !_verifiedOnly || worker.isVerified;

        return matchesQuery && matchesCategory && matchesDistance && matchesRating && matchesVerified;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialCategory: _selectedCategory,
        initialDistance: _maxDistance,
        initialRating: _minRating,
        initialVerified: _verifiedOnly,
        onApply: (category, distance, rating, verified) {
          setState(() {
            _selectedCategory = category;
            _maxDistance = distance;
            _minRating = rating;
            _verifiedOnly = verified;
          });
          _applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : _filteredWorkers.isEmpty 
                  ? _buildEmptyState()
                  : _buildResultsList(),
          ),
        ],
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: -1),
    );
  }

  Widget _buildHeader() {
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
                  onChanged: (_) => _applyFilters(),
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
      itemCount: _filteredWorkers.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Workers', style: AppTypography.headlineMedium.copyWith(color: theme.colorScheme.onSurface)),
                Text(
                  'Showing ${_filteredWorkers.length} results',
                  style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        return _buildWorkerCard(_filteredWorkers[index - 1]);
      },
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
                          if (worker.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, color: colorScheme.primary, size: 18),
                          ],
                        ],
                      ),
                      Text(worker.specialty, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(worker.rating.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface)),
                          Text(' • ${worker.reviewCount} jobs', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
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
              children: worker.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag, 
                  style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700)
                ),
              )).toList(),
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
                      TextSpan(text: '₱${worker.hourlyRate.toInt()}'),
                      TextSpan(text: '/hr', style: AppTypography.bodySmall.copyWith(fontSize: 12, color: colorScheme.onSurfaceVariant)),
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
                  _selectedCategory = null;
                  _maxDistance = 20.0;
                  _minRating = 0.0;
                  _verifiedOnly = false;
                });
                _applyFilters();
              },
              child: Text('Clear Filters', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? initialCategory;
  final double initialDistance;
  final double initialRating;
  final bool initialVerified;
  final Function(String?, double, double, bool) onApply;

  const _FilterBottomSheet({
    required this.initialCategory,
    required this.initialDistance,
    required this.initialRating,
    required this.initialVerified,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _category;
  double _distance = 5.0;
  double _rating = 0.0;
  bool _verified = true;

  final List<String> _categories = ['Electrical', 'Plumbing', 'Tutoring', 'Cleaning', 'Carpentry', 'Laundry', 'Gardening'];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _distance = widget.initialDistance;
    _rating = widget.initialRating;
    _verified = widget.initialVerified;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
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
              Text('Filters', style: AppTypography.headlineMedium.copyWith(color: colorScheme.onSurface)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _category = null;
                    _distance = 5.0;
                    _rating = 0.0;
                    _verified = true;
                  });
                },
                child: Text('Reset', style: TextStyle(color: colorScheme.primary)),
              ),
            ],
          ),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          
          Align(alignment: Alignment.centerLeft, child: Text('Service Category', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) => ChoiceChip(
              label: Text(cat),
              selected: _category == cat,
              onSelected: (selected) => setState(() => _category = selected ? cat : null),
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(color: _category == cat ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
              showCheckmark: false,
              backgroundColor: colorScheme.surfaceVariant.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            )).toList(),
          ),
          
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              Text('Up to ${_distance.toInt()} km', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          Slider(
            value: _distance,
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
            onChanged: (val) => setState(() => _distance = val),
          ),

          const SizedBox(height: 32),

          Align(alignment: Alignment.centerLeft, child: Text('Minimum Rating', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRatingOption('Any', 0.0),
              const SizedBox(width: 8),
              _buildRatingOption('3.5+', 3.5),
              const SizedBox(width: 8),
              _buildRatingOption('4.5+', 4.5),
            ],
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verified Workers Only', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                  Text('Show only identity-verified professionals', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
              Switch(
                value: _verified,
                activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                activeColor: colorScheme.primary,
                onChanged: (val) => setState(() => _verified = val),
              ),
            ],
          ),

          const SizedBox(height: 40),
          
          PrimaryButton(
            label: 'Show Results',
            onPressed: () {
              widget.onApply(_category, _distance, _rating, _verified);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRatingOption(String label, double value) {
    final isSelected = _rating == value;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rating = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surface,
            border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              if (value > 0) ...[
                const SizedBox(width: 4),
                Icon(Icons.star, color: isSelected ? colorScheme.primary : Colors.amber, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
