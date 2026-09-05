import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/trust_tier.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/navigation/app_header.dart';

class JobPostDetailScreen extends StatefulWidget {
  final String postId;

  const JobPostDetailScreen({super.key, required this.postId});

  @override
  State<JobPostDetailScreen> createState() => _JobPostDetailScreenState();
}

class _JobPostDetailScreenState extends State<JobPostDetailScreen> {
  late Future<JobPostListing?> _postFuture;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  void _loadPost() {
    setState(() {
      _postFuture = context.read<WorkerProvider>().getJobPostDetail(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Service Post'),
          Expanded(
            child: FutureBuilder<JobPostListing?>(
              future: _postFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(colorScheme, snapshot.error.toString());
                }

                final listing = snapshot.data;
                if (listing == null) {
                  return _buildNotFound(colorScheme);
                }

                return _buildPost(listing, colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPost(JobPostListing listing, ColorScheme colorScheme) {
    final worker = listing.worker;
    final post = listing.post;
    final canBook = post.isActive && post.isAvailable;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              // Inactive post warning banner
              if (!post.isActive) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This job post is currently inactive and cannot be booked.',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Worker Profile Header Link
              InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  '${AppRouter.workerProfile}/${worker.id}',
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(worker.avatarUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.name,
                              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${post.category} · ${worker.barangay}',
                              style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              '~${worker.distance}',
                              style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(worker.trustTier.info.icon, color: worker.trustTier.info.color),
                    ],
                  ),
                ),
              ),

              Text(
                post.title,
                style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                post.description,
                style: AppTypography.bodyLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Rate & Availability Info
              Row(
                children: [
                  Text(
                    'From ₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: !post.isActive
                        ? Colors.grey
                        : (post.isAvailable ? Colors.green : Colors.orange),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    !post.isActive
                        ? 'Inactive'
                        : (post.isAvailable ? 'Available Now' : 'By Schedule'),
                    style: AppTypography.bodySmall.copyWith(
                      color: !post.isActive ? colorScheme.error : null,
                      fontWeight: !post.isActive ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Vertical Image List or Empty State
              if (post.images.isNotEmpty || post.imageUrls.isNotEmpty) ...[
                Text(
                  'Service Photos',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                // Render full images vertically
                ...((post.images.isNotEmpty
                    ? post.images.map((img) => img.imageUrl).toList()
                    : post.imageUrls)
                    .map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'No photos uploaded for this service',
                        style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Sticky Bottom Booking Button
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: PrimaryButton(
              label: !post.isActive
                  ? 'Service Inactive'
                  : (!post.isAvailable ? 'Currently Unavailable' : 'Book This Service'),
              onPressed: canBook
                  ? () => Navigator.pushNamed(
                        context,
                        '${AppRouter.sendBookingRequest}/${worker.id}?postId=${post.id}',
                      )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('This post is no longer available', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'The job post may have been removed or deactivated by the worker.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            const Text('Failed to load post', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadPost,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
