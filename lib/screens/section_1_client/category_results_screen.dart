import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/barangay_model.dart';
import '../../data/models/trust_tier.dart';
import '../../widgets/navigation/app_bottom_nav.dart';

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
  late Future<List<JobPostListing>> _listingsFuture;
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
    final authProvider = context.read<AuthProvider>();
    workerProvider.setAdvancedFilters(
      categories: [widget.categoryName],
      barangay: _selectedBarangay,
    );
    _listingsFuture = workerProvider.getFilteredWorkers(
      userBarangayName: authProvider.userBarangay,
    ).then((list) {
      if (_verifiedOnly) {
        list = list.where((l) => l.worker.isVerified).toList();
      }
      if (_availableOnly) {
        list = list.where((l) => l.worker.isAvailable).toList();
      }
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                  // Filter row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedBarangay,
                            decoration: InputDecoration(
                              hintText: 'All Barangays',
                              hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.1),
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Text(
                              'Verified only',
                              style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: _verifiedOnly,
                              onChanged: (val) {
                                setState(() {
                                  _verifiedOnly = val;
                                  _loadListings();
                                });
                              },
                              activeColor: colorScheme.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Row(
                          children: [
                            Text(
                              'Available',
                              style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: _availableOnly,
                              onChanged: (val) {
                                setState(() {
                                  _availableOnly = val;
                                  _loadListings();
                                });
                              },
                              activeColor: colorScheme.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<JobPostListing>>(
              future: _listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                }
                final listings = snapshot.data ?? [];
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
                    return _WorkerResultCard(listing: listings[index - 1]);
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

class _WorkerResultCard extends StatelessWidget {
  final JobPostListing listing;

  const _WorkerResultCard({required this.listing});

  @override
  Widget build(BuildContext context) {
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
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${worker.rating} (${worker.reviewCount} reviews)',
                        style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        worker.distance,
                        style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From ₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TrustBadge(worker: worker),
                const SizedBox(height: 8),
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
}

class _TrustBadge extends StatelessWidget {
  final Worker worker;

  const _TrustBadge({required this.worker});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
        mainAxisSize: MainAxisSize.min,
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
}
