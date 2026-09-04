import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/job_post_model.dart';
import '../../widgets/navigation/app_back_button.dart';

/// W4: Manage Posts Screen
/// Route: /manage-job-posts
class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> {
  late Future<List<JobPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = context.read<WorkerProvider>().getWorkerById(AppConstants.mockWorkerId).then(
      (worker) => worker?.jobPosts ?? [],
    );
  }

  Future<void> _reactivatePost(JobPost post) async {
    final colorScheme = Theme.of(context).colorScheme;
    final workerProvider = context.read<WorkerProvider>();
    final updated = post.copyWith(isAvailable: true);
    final result = await workerProvider.updateJobPost(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Post reactivated' : result.message),
          backgroundColor: result.success ? colorScheme.primary : colorScheme.error,
        ),
      );
      if (result.success) setState(() => _loadPosts());
    }
  }

  Future<void> _deactivatePost(JobPost post) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeactivateSheet(postTitle: post.title),
    );
    if (confirmed == true && mounted) {
      final workerProvider = context.read<WorkerProvider>();
      final result = await workerProvider.deleteJobPost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Post deactivated' : result.message),
            backgroundColor: result.success ? Colors.orange : colorScheme.error,
          ),
        );
        if (result.success) setState(() => _loadPosts());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.createJobPost)
            .then((_) => setState(() => _loadPosts())),
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manage Posts',
                      style: AppTypography.headlineMedium.copyWith(
                        color: colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<JobPost>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                }
                final posts = snapshot.data ?? [];
                final active = posts.where((p) => p.isAvailable).toList();
                final inactive = posts.where((p) => !p.isAvailable).toList();

                if (posts.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (active.isNotEmpty) ...[
                      _sectionLabel('Active Posts', colorScheme),
                      const SizedBox(height: 8),
                      ...active.map((p) => _PostCard(
                        post: p,
                        onEdit: () => Navigator.pushNamed(context, '${AppRouter.editJobPost}/${p.id}')
                            .then((_) => setState(() => _loadPosts())),
                        onDeactivate: () => _deactivatePost(p),
                      )),
                      const SizedBox(height: 16),
                    ],
                    if (inactive.isNotEmpty) ...[
                      _sectionLabel('Inactive Posts', colorScheme),
                      const SizedBox(height: 8),
                      ...inactive.map((p) => _PostCard(
                        post: p,
                        onEdit: () => Navigator.pushNamed(context, '${AppRouter.editJobPost}/${p.id}')
                            .then((_) => setState(() => _loadPosts())),
                        onReactivate: () => _reactivatePost(p),
                      )),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, ColorScheme colorScheme) {
    return Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add_outlined, size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No posts yet', style: AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Create your first post to start receiving bookings.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRouter.createJobPost)
                  .then((_) => setState(() => _loadPosts())),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final JobPost post;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;

  const _PostCard({
    required this.post,
    required this.onEdit,
    this.onDeactivate,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = post.isAvailable;

    return Dismissible(
      key: Key('post_${post.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.error : colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.visibility_off : Icons.visibility,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'Deactivate' : 'Reactivate',
              style: TextStyle(color: colorScheme.onPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        if (isActive && onDeactivate != null) {
          onDeactivate!();
        } else if (!isActive && onReactivate != null) {
          onReactivate!();
        }
        return false; // We handle state ourselves
      },
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.surface : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: isActive
                ? [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.outlineVariant.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline,
                  color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      post.category,
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From ₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.outlineVariant.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeactivateSheet extends StatelessWidget {
  final String postTitle;

  const _DeactivateSheet({required this.postTitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deactivate this post?', style: AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Your post will be hidden from the client feed. You can reactivate it anytime.',
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Deactivate', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Keep Active', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
