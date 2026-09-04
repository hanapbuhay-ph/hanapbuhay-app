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
    _postFuture = _loadPost();
  }

  Future<JobPostListing?> _loadPost() async {
    final workers = await context.read<WorkerProvider>().getTopRatedWorkers();
    for (final worker in workers) {
      for (final post in worker.jobPosts) {
        if (post.id == widget.postId) {
          return JobPostListing(worker: worker, post: post);
        }
      }
    }
    return null;
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
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, '${AppRouter.workerProfile}/${worker.id}'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 26, backgroundImage: NetworkImage(worker.avatarUrl)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(worker.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                            Text('${post.category} · ${worker.barangay}', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                            Text('~${worker.distance}', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(worker.trustTier.info.icon, color: worker.trustTier.info.color),
                    ],
                  ),
                ),
              ),
              Text(post.title, style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(post.description, style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('From ₱${post.startingRate.toInt()}${post.rateType.shortLabel}', style: AppTypography.labelLarge.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Icon(Icons.circle, size: 10, color: post.isAvailable ? Colors.green : Colors.orange),
                  const SizedBox(width: 6),
                  Text(post.isAvailable ? 'Available Now' : 'By Schedule', style: AppTypography.bodySmall),
                ],
              ),
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...post.imageUrls.map((url) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const AspectRatio(aspectRatio: 4 / 3, child: Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => const AspectRatio(aspectRatio: 4 / 3, child: Center(child: Icon(Icons.broken_image_outlined))),
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: PrimaryButton(
              label: 'Book This Service',
              onPressed: post.isAvailable
                  ? () => Navigator.pushNamed(context, '${AppRouter.sendBookingRequest}/${worker.id}?postId=${post.id}')
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
            const Text('This post is no longer available'),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}
