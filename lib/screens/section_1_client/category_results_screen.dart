import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/worker_provider.dart';
import '../../data/repositories/worker_repository.dart';
import '../../data/models/barangay_model.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import '../../widgets/cards/job_post_card.dart';

/// C3: Category Results Screen
/// Route: /category-results/{categoryId}?name=categoryName
class CategoryResultsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryResultsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryResultsScreen> createState() => _CategoryResultsScreenState();
}

class _CategoryResultsScreenState extends State<CategoryResultsScreen> {
  late Future<CategoryWorkerResponse> _listingsFuture;
  String? _selectedBarangay;
  bool _verifiedOnly = false;
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    final workerProvider = context.read<WorkerProvider>();
    _listingsFuture = workerProvider.getCategoryWorkers(
      widget.categoryId,
      barangayName: _selectedBarangay,
      verifiedOnly: _verifiedOnly,
      availableOnly: _availableOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              color: colorScheme.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        widget.categoryName,
                        style: AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        final barangayDropdown = _buildBarangayDropdown(colorScheme);
                        final toggleFilters = _buildToggleFilters(colorScheme);

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              barangayDropdown,
                              const SizedBox(height: 12),
                              toggleFilters,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: barangayDropdown),
                            const SizedBox(width: 16),
                            toggleFilters,
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<CategoryWorkerResponse>(
              future: _listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                }
                final listings = snapshot.data?.listings ?? [];
                if (listings.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: listings.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${listings.length} worker${listings.length == 1 ? '' : 's'} available',
                          style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return JobPostCard(listing: listings[index - 1]);
                  },

                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBarangayDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBarangay,
      decoration: InputDecoration(
        hintText: 'All Barangays',
        hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All Barangays')),
        ...Barangay.trinidadBarangays.map((b) => DropdownMenuItem(
          value: b.name,
          child: Text(b.name, style: const TextStyle(fontSize: 13)),
        )),
      ],
      onChanged: (val) {
        setState(() {
          _selectedBarangay = val;
          _loadListings();
        });
      },
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      isDense: true,
    );
  }

  Widget _buildToggleFilters(ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      children: [
        _buildToggle(
          label: 'Verified only',
          value: _verifiedOnly,
          colorScheme: colorScheme,
          onChanged: (value) => setState(() {
            _verifiedOnly = value;
            _loadListings();
          }),
        ),
        _buildToggle(
          label: 'Available',
          value: _availableOnly,
          colorScheme: colorScheme,
          onChanged: (value) => setState(() {
            _availableOnly = value;
            _loadListings();
          }),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ColorScheme colorScheme,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(width: 4),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No workers found',
              style: AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedBarangay = null;
                  _verifiedOnly = false;
                  _availableOnly = false;
                  _loadListings();
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Clear Filters', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

