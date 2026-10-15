import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_posts_provider.dart';
import '../../widgets/cards/job_post_card.dart';
import '../../widgets/navigation/app_bottom_nav.dart';

class SavedServicesScreen extends StatefulWidget {
  const SavedServicesScreen({super.key});

  @override
  State<SavedServicesScreen> createState() => _SavedServicesScreenState();
}

class _SavedServicesScreenState extends State<SavedServicesScreen> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadSavedServices();
  }

  void _loadSavedServices() {
    final userId = context.read<AuthProvider>().userId;
    _loadFuture = context.read<SavedPostsProvider>().loadForUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final savedPosts = context.watch<SavedPostsProvider>().savedPosts;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved services',
                          style: AppTypography.headlineSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Your bookmarked local services',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (savedPosts.isNotEmpty)
                    Text(
                      '${savedPosts.length}',
                      style: AppTypography.labelLarge.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<void>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState(colorScheme, snapshot.error!);
                }
                if (savedPosts.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }

                return ListView.builder(
                  key: const ValueKey('saved-services-list'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: savedPosts.length,
                  itemBuilder: (context, index) =>
                      JobPostCard(listing: savedPosts[index]),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved services yet',
              style: AppTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save a service from the home feed to keep it here for later.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load saved services',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(_loadSavedServices),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
