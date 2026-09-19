import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/trust_tier.dart';
import '../../data/models/worker_model.dart';

/// Shared feed card used on the Client Home screen and Category Results screen.
///
/// Tapping the card navigates to the post detail screen.
/// Tapping the worker avatar / name navigates to the worker profile.
class JobPostCard extends StatelessWidget {
  final JobPostListing listing;

  const JobPostCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final worker = listing.worker;
    final post = listing.post;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '${AppRouter.clientPostDetail}/${post.id}'),
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
            // Top row: avatar + name + barangay + trust badge
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, '${AppRouter.workerProfile}/${worker.id}'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(worker.avatarUrl),
                      ),
                      if (worker.trustTier == TrustTier.verified ||
                          worker.trustTier == TrustTier.trusted)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: colorScheme.onPrimary,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '${AppRouter.workerProfile}/${worker.id}'),
                        child: Text(
                          worker.name,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        post.category,
                        style: AppTypography.bodySmall
                            .copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              worker.barangay,
                              style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _TrustBadge(worker: worker),
              ],
            ),

            const SizedBox(height: 10),

            // Post image (if any)
            if (post.images.isNotEmpty || post.imageUrls.isNotEmpty) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.thumbnailUrl ??
                          post.previewImageUrl ??
                          post.imageUrls.first,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 180,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 180,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.image_outlined)),
                      ),
                    ),
                  ),
                  if ((post.images.isNotEmpty
                          ? post.images.length
                          : post.imageUrls.length) >
                      1)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${post.images.isNotEmpty ? post.images.length : post.imageUrls.length} photos',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

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
              style: AppTypography.bodySmall
                  .copyWith(color: colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Bottom row: distance + rate + availability dot
            Row(
              children: [
                Icon(Icons.near_me_outlined,
                    size: 13, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    worker.distance,
                    style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    color: worker.isAvailable
                        ? colorScheme.primary
                        : Colors.orange,
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
        icon = Icons.verified_rounded;
        break;
      case TrustTier.verified:
        color = colorScheme.primary;
        label = 'Verified';
        icon = Icons.verified_rounded;
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
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
