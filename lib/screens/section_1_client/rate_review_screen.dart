import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/booking_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';

class RateReviewScreen extends StatefulWidget {
  final String bookingId;

  const RateReviewScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  Booking? _booking;
  Worker? _worker;
  bool _isLoading = true;
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  
  // Submit Button States
  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final booking = await context.read<BookingProvider>().getBookingById(widget.bookingId);
    if (booking != null) {
      final worker = await context.read<WorkerProvider>().getWorkerById(booking.workerId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _worker = worker;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedRating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both a rating and a comment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await context.read<BookingProvider>().submitReview(
        bookingId: widget.bookingId,
        workerId: _worker!.id,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (result.success && mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });

        // Brief delay to show success state
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          Navigator.pop(context, true); // Return success to history screen
        }
      } else if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_booking == null || _worker == null) {
      return const Scaffold(body: Center(child: Text('Booking details not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(title: 'HanapBuhay'),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Title
                  Text(
                    'Rate Your Experience',
                    style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was the service provided by ${_worker!.name.split(' ').first}?',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Worker Summary Card
                  _buildWorkerCard(_worker!),
                  const SizedBox(height: 40),

                  // Star Selector
                  Text(
                    'Select Rating',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _buildStarRating(),
                  const SizedBox(height: 40),

                  // Written Review
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Write a Review',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 5,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Tell us about your experience...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.surfaceContainerLow,
            backgroundImage: NetworkImage(worker.avatarUrl),
          ),
          const SizedBox(height: 16),
          Text(
            worker.name,
            style: AppTypography.headlineMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              worker.specialty.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSecondaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final ratingValue = index + 1;
        final isSelected = _selectedRating >= ratingValue;
        return GestureDetector(
          onTap: () => setState(() => _selectedRating = ratingValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: 48,
              color: isSelected ? Colors.amber : AppColors.outlineVariant,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton() {
    Color bgColor = AppColors.primary;
    String label = 'Submit Review';
    Widget icon = const SizedBox.shrink();

    if (_isSubmitting) {
      label = 'Submitting...';
      icon = const Padding(
        padding: EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    } else if (_isSuccess) {
      bgColor = AppColors.leafBright;
      label = 'Review Submitted';
      icon = const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Icon(Icons.check_circle, color: Colors.white, size: 20),
      );
    }

    return GestureDetector(
      onTap: (_isSubmitting || _isSuccess) ? null : _handleSubmit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
