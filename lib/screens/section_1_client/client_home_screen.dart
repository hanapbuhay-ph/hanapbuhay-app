import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../providers/notification_provider.dart';
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

  void _reloadFeed() {
    setState(() {
      _filteredWorkersFuture = context.read<WorkerProvider>().getFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HanapBuhay',
                      style: AppTypography.headlineSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Skills today. Better tomorrow.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Search workers',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.workerSearch),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerLow,
                    foregroundColor: colorScheme.onSurface,
                    fixedSize: const Size(38, 38),
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.search_rounded),
                ),
                const SizedBox(width: 6),
                StreamBuilder<int>(
                  stream: context.read<NotificationProvider>().getUnreadCount(),
                  builder: (context, snapshot) {
                    final hasUnread = (snapshot.data ?? 0) > 0;
                    return IconButton(
                      tooltip: 'Notifications',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRouter.notificationCenter,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerLow,
                        foregroundColor: colorScheme.onSurface,
                        fixedSize: const Size(38, 38),
                        shape: const CircleBorder(),
                      ),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: colorScheme.onSurface,
                          ),
                          if (hasUnread)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: colorScheme.surface,
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() => _loadData());
              },
              color: colorScheme.primary,
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: ResponsiveContent(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        child: _buildWelcomeBanner(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildCategorySection(),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 4,
                        child: ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore local services',
                              style: AppTypography.headlineSmall.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Find skilled people ready to help',
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                      _buildFeedSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Header owned by TabShell

  Widget _buildWelcomeBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 176,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -46,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 112, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Find the right skills.\nGet the right help.',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Connect with skilled people in your community.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 0,
            child: Container(
              width: 84,
              height: 84,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.94),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<ServiceCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <ServiceCategory>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            categories.isEmpty) {
          return const SizedBox(
            height: 88,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: AppTypography.headlineSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.browseCategory),
                  child: Text(
                    'View All',
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildCategoryCard(categories[index], index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(ServiceCategory category, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = index.isEven || isDark
        ? colorScheme.primary
        : const Color(0xFF2674D9);
    final tileColor = isDark
        ? colorScheme.surfaceContainerHigh
        : index.isEven
        ? const Color(0xFFEAF6EE)
        : const Color(0xFFEDF4FF);

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '${AppRouter.categoryResults}/${category.id}?name=${Uri.encodeComponent(category.label)}',
      ),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 232,
        height: 108,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Icon(category.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: accent, size: 24),
          ],
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
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              const SizedBox(height: 32),
              Icon(Icons.cloud_off_outlined, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Could not load worker listings',
                style: AppTypography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: _reloadFeed,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          );
        }
        final listings = snapshot.data?.posts ?? [];
        if (listings.isEmpty) {
          return Column(
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.search_off,
                size: 56,
                color: colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No workers found',
                style: AppTypography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or check back later.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          itemCount: listings.length,
          itemBuilder: (context, index) =>
              JobPostCard(listing: listings[index]),
          separatorBuilder: (context, index) => SizedBox(
            height: 4,
            child: ColoredBox(color: colorScheme.surfaceContainerHighest),
          ),
        );
      },
    );
  }
}

class _AdvancedFilterBottomSheet extends StatefulWidget {
  const _AdvancedFilterBottomSheet();

  @override
  State<_AdvancedFilterBottomSheet> createState() =>
      _AdvancedFilterBottomSheetState();
}

class _AdvancedFilterBottomSheetState
    extends State<_AdvancedFilterBottomSheet> {
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
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Advanced Filters',
                style: AppTypography.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategories = [];
                    _selectedBarangay = null;
                    _selectedRateTypes = [];
                    _onlyAvailable = false;
                  });
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  Text(
                    'Service Category',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<ServiceCategory>>(
                    future: workerProvider.getCategories(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = _selectedCategories.contains(
                            cat.id,
                          );
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
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Barangay',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBarangay,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.1,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    hint: const Text('All Barangays'),
                    items: Barangay.trinidadBarangays
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBarangay = val),
                    dropdownColor: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Rate Type',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.2),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
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
                          Text(
                            'Available Now',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Show only workers ready to work',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _onlyAvailable,
                        onChanged: (val) =>
                            setState(() => _onlyAvailable = val),
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
