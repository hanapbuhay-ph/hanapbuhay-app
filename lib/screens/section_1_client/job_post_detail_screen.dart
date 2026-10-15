import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/job_post_model.dart';
import '../../data/models/trust_tier.dart';
import '../../data/models/worker_model.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/navigation/app_back_button.dart';

class JobPostDetailScreen extends StatefulWidget {
  final String postId;

  const JobPostDetailScreen({super.key, required this.postId});

  @override
  State<JobPostDetailScreen> createState() => _JobPostDetailScreenState();
}

class _JobPostDetailScreenState extends State<JobPostDetailScreen> {
  late Future<JobPostListing?> _postFuture;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  void _loadPost() {
    setState(() {
      _postFuture = context.read<WorkerProvider>().getJobPostDetail(
        widget.postId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(colorScheme),
          Expanded(
            child: FutureBuilder<JobPostListing?>(
              future: _postFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(
                    colorScheme,
                    snapshot.error.toString(),
                  );
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return SafeArea(
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
            const AppBackButton(),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HanapBuhay',
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Service post',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildPost(JobPostListing listing, ColorScheme colorScheme) {
    final worker = listing.worker;
    final post = listing.post;
    final canBook = post.isActive && post.isAvailable;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              // Inactive post warning banner
              if (!post.isActive) ...[
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
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

              if (post.images.isNotEmpty || post.imageUrls.isNotEmpty) ...[
                _buildGallery(post, colorScheme),
                SizedBox(
                  height: 4,
                  child: ColoredBox(color: colorScheme.surfaceContainerHighest),
                ),
              ],

              // Worker Profile Header Link
              InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  '${AppRouter.workerProfile}/${worker.id}',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              post.category,
                              style: AppTypography.labelSmall.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${worker.barangay} · ${worker.distance}',
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${worker.rating.toStringAsFixed(1)} · ${worker.completedJobsCount} jobs done',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: worker.trustTier.info.color.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          worker.trustTier.info.icon,
                          color: worker.trustTier.info.color,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  post.title,
                  style: AppTypography.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  post.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (worker.bio.isNotEmpty || worker.specialty.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${worker.name}',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        worker.bio.isNotEmpty
                            ? worker.bio
                            : '${worker.specialty} services in ${worker.barangay}.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // Rate & Availability Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox(
                        colorScheme,
                        Icons.payments_outlined,
                        '₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                        'Starting rate',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox(
                        colorScheme,
                        Icons.schedule_outlined,
                        !post.isActive
                            ? 'Inactive'
                            : (post.isAvailable ? 'Available' : 'By schedule'),
                        'Availability',
                        muted: !post.isActive,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (post.images.isEmpty && post.imageUrls.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No photos uploaded for this service',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Sticky Bottom Booking Button
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Starting from',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '₱${post.startingRate.toInt()}${post.rateType.shortLabel}',
                        style: AppTypography.labelLarge.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: !post.isActive
                        ? 'Service Inactive'
                        : (!post.isAvailable
                              ? 'Currently Unavailable'
                              : 'Send Booking Request'),
                    onPressed: canBook
                        ? () => _handleBooking(worker, post)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBooking(Worker worker, JobPost post) async {
    final isVerified =
        worker.trustTier == TrustTier.verified ||
        worker.trustTier == TrustTier.trusted;

    if (!isVerified) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 10),
              Expanded(child: Text('Worker Not Yet Verified')),
            ],
          ),
          content: const Text(
            'This worker is not currently marked as verified or trusted. '
            'HanapBuhay cannot fully guarantee their identity or standing. '
            'You may review this information and decide whether to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue to Booking'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '${AppRouter.sendBookingRequest}/${worker.id}?postId=${post.id}',
    );
  }

  Widget _buildGallery(JobPost post, ColorScheme colorScheme) {
    final urls = post.images.isNotEmpty
        ? post.images.map((image) => image.imageUrl).toList()
        : post.imageUrls;
    final selectedImageIndex = _selectedImageIndex.clamp(0, urls.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 300,
          child: InkWell(
            key: const ValueKey('service-post-open-image'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    _ServiceImageViewer(imageUrl: urls[selectedImageIndex]),
              ),
            ),
            child: CachedNetworkImage(
              key: const ValueKey('service-post-main-image'),
              imageUrl: urls[selectedImageIndex],
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
                  Icons.broken_image_outlined,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => InkWell(
                  key: ValueKey('service-post-thumbnail-$index'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: 78,
                    height: 64,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: index == selectedImageIndex
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: urls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoBox(
    ColorScheme colorScheme,
    IconData icon,
    String value,
    String label, {
    bool muted = false,
  }) {
    final accent = muted ? colorScheme.onSurfaceVariant : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text(
              'This post is no longer available',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The job post may have been removed or deactivated by the worker.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
            const Text(
              'Failed to load post',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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

class _ServiceImageViewer extends StatefulWidget {
  final String imageUrl;

  const _ServiceImageViewer({required this.imageUrl});

  @override
  State<_ServiceImageViewer> createState() => _ServiceImageViewerState();
}

class _ServiceImageViewerState extends State<_ServiceImageViewer> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    setState(() => _isDownloading = true);

    try {
      final response = await http
          .get(Uri.parse(widget.imageUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _showMessage('Could not download this photo. Please try again.');
        return;
      }
      if (response.bodyBytes.isEmpty) {
        _showMessage('The photo could not be downloaded. Please try again.');
        return;
      }

      var hasGalleryAccess = await Gal.hasAccess();
      if (!hasGalleryAccess) {
        hasGalleryAccess = await Gal.requestAccess();
      }
      if (!hasGalleryAccess) {
        _showMessage('Allow photo access to save this image to your gallery.');
        return;
      }

      await Gal.putImageBytes(
        response.bodyBytes,
        name: 'hanapbuhay_service_${DateTime.now().millisecondsSinceEpoch}',
      );
      _showMessage('Photo saved to your gallery.');
    } on GalException catch (error) {
      _showMessage(error.type.message);
    } on http.ClientException {
      _showMessage('Check your internet connection and try downloading again.');
    } on TimeoutException {
      _showMessage('The download timed out. Please try again.');
    } on FormatException {
      _showMessage('This photo has an invalid address and could not be saved.');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo'),
        actions: [
          IconButton(
            tooltip: 'Download image',
            onPressed: _isDownloading ? null : _downloadImage,
            icon: _isDownloading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
