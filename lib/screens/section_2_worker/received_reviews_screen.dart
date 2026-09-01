import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/navigation/app_header.dart';

class ReceivedReviewsScreen extends StatefulWidget {
  const ReceivedReviewsScreen({super.key});

  @override
  State<ReceivedReviewsScreen> createState() => _ReceivedReviewsScreenState();
}

class _ReceivedReviewsScreenState extends State<ReceivedReviewsScreen> {
  Worker? _worker;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workerProvider = context.read<WorkerProvider>();
    // For demo/mock, assuming current worker is 'w1'
    final worker = await workerProvider.getWorkerById('w1');
    if (mounted) {
      setState(() {
        _worker = worker;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_worker == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            const AppHeader(title: 'My Reviews'),
            const Expanded(child: Center(child: Text('Profile not found'))),
          ],
        ),
      );
    }

    final reviews = _worker!.reviews;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(title: 'My Reviews'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildRatingHeader(_worker!),
                  const SizedBox(height: 32),
                  Text(
                    'Review History',
                    style: AppTypography.headlineSmall.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (reviews.isEmpty)
                    _buildEmptyState()
                  else
                    ...reviews.map((r) => _buildReviewCard(r)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHeader(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            worker.rating.toStringAsFixed(1),
            style: AppTypography.displayLarge.copyWith(
              fontSize: 48,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < worker.rating.floor() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 28,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on ${worker.reviewCount} client reviews',
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(WorkerReview review) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(review.reviewerAvatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${review.date.day}/${review.date.month}/${review.date.year}',
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.comment,
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Re: Booking #${Booking.formatBookingCode(review.id, review.date)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
