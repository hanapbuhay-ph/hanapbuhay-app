import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
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
    // In a real app, we would pass filters to the repository
    // For mock, we fetch all and filter client-side
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
        
        // Mock distance parsing (e.g., "1.2 km" -> 1.2)
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Sticky Header
          _buildHeader(),

          // Content
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: const Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
        ),
        child: Row(
          children: [
            const AppBackButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: const InputDecoration(
                    hintText: 'Search for workers...',
                    prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
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
                const Text('Available Workers', style: AppTypography.headlineMedium),
                Text(
                  'Showing ${_filteredWorkers.length} results',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
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
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '${AppRouter.workerProfile}/${worker.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                          Text(worker.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
                          if (worker.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppColors.primary, size: 18),
                          ],
                        ],
                      ),
                      Text(worker.specialty, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(worker.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(' • ${worker.reviewCount} jobs', style: AppTypography.bodySmall),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag, 
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.surfaceContainerHigh),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(worker.distance, style: AppTypography.bodySmall),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: AppTypography.headlineMedium.copyWith(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: '₱${worker.hourlyRate.toInt()}'),
                      TextSpan(text: '/hr', style: AppTypography.bodySmall.copyWith(fontSize: 12)),
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
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off, size: 60, color: AppColors.outlineVariant),
            ),
            const SizedBox(height: 24),
            const Text('No workers found', style: AppTypography.headlineMedium),
            const SizedBox(height: 12),
            const Text(
              'We couldn\'t find anyone matching your current filters. Try adjusting your search criteria.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
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
              child: const Text('Clear Filters', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: AppTypography.headlineMedium),
              TextButton(
                onPressed: () {
                  setState(() {
                    _category = null;
                    _distance = 5.0;
                    _rating = 0.0;
                    _verified = true;
                  });
                },
                child: const Text('Reset', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 24),
          
          // Category
          Align(alignment: Alignment.centerLeft, child: Text('Service Category', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) => ChoiceChip(
              label: Text(cat),
              selected: _category == cat,
              onSelected: (selected) => setState(() => _category = selected ? cat : null),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: _category == cat ? Colors.white : AppColors.onSurfaceVariant),
              showCheckmark: false,
              backgroundColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            )).toList(),
          ),
          
          const SizedBox(height: 32),

          // Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
              Text('Up to ${_distance.toInt()} km', style: AppTypography.bodySmall),
            ],
          ),
          Slider(
            value: _distance,
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _distance = val),
          ),

          const SizedBox(height: 32),

          // Rating
          Align(alignment: Alignment.centerLeft, child: Text('Minimum Rating', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700))),
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

          // Verified
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verified Workers Only', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text('Show only identity-verified professionals', style: AppTypography.bodySmall),
                ],
              ),
              Switch(
                value: _verified,
                activeThumbColor: AppColors.primary,
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
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rating = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
              if (value > 0) ...[
                const SizedBox(width: 4),
                Icon(Icons.star, color: isSelected ? AppColors.primary : Colors.amber, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
