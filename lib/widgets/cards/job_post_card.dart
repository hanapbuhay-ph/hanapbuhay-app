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
class JobPostCard extends StatefulWidget {
  final JobPostListing listing;

  const JobPostCard({super.key, required this.listing});

  @override
  State<JobPostCard> createState() => _JobPostCardState();
}

class _JobPostCardState extends State<JobPostCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final worker = widget.listing.worker;
    final post = widget.listing.post;

    final hasImages = post.images.isNotEmpty || post.imageUrls.isNotEmpty;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '${AppRouter.clientPostDetail}/${post.id}',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '${AppRouter.workerProfile}/${worker.id}',
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundImage: NetworkImage(worker.avatarUrl),
                        ),
                        if (worker.trustTier == TrustTier.verified ||
                            worker.trustTier == TrustTier.trusted)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 17,
                              height: 17,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_rounded,
                                color: colorScheme.onPrimary,
                                size: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '${AppRouter.workerProfile}/${worker.id}',
                          ),
                          child: Text(
                            worker.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${post.category} · ${worker.barangay}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              ' · ',
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              worker.rating.toStringAsFixed(1),
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TrustBadge(worker: worker),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      post.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (hasImages) _buildPostImage(context, post),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.near_me_outlined,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      worker.distance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: worker.isAvailable
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    worker.isAvailable ? 'Available' : 'Busy',
                    style: AppTypography.labelSmall.copyWith(
                      color: worker.isAvailable
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _isSaved = !_isSaved),
                      icon: Icon(
                        _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 18,
                        color: _isSaved
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        _isSaved ? 'Saved' : 'Save',
                        style: AppTypography.labelLarge.copyWith(
                          color: _isSaved
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '${AppRouter.clientPostDetail}/${post.id}',
                      ),
                      icon: Icon(
                        Icons.open_in_new_rounded,
                        size: 17,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        'View service',
                        style: AppTypography.labelLarge.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage(BuildContext context, JobPost post) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoCount = post.images.isNotEmpty
        ? post.images.length
        : post.imageUrls.length;
    return AspectRatio(
      aspectRatio: 1.65,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl:
                post.thumbnailUrl ??
                post.previewImageUrl ??
                post.imageUrls.first,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 32,
              ),
            ),
          ),
          if (photoCount > 1)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$photoCount',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
        color = colorScheme.secondary;
        label = 'Trusted';
        icon = Icons.verified_rounded;
        break;
      case TrustTier.verified:
        color = colorScheme.primary;
        label = 'Verified';
        icon = Icons.verified_rounded;
        break;
      default:
        color = colorScheme.onSurfaceVariant;
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
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
