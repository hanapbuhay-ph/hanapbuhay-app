import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
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
  bool _isLoading = true;
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  
  // Submit Button States
  bool _isSubmitting = false;
  bool _isSuccess = false;
  Map<String, dynamic>? _serverErrors;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();
    final booking = await bookingProvider.getBookingById(widget.bookingId);
    if (mounted) {
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
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
        final colorScheme = Theme.of(context).colorScheme;
        setState(() {
          _isSubmitting = false;
          _serverErrors = result.errors;
        });
        final msgs = <String>[];
        (result.errors ?? const {}).forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            msgs.add('• ${value.join(', ')}');
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msgs.isEmpty ? result.message : msgs.join('\n')),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Booking details not found')));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'HanapBuhay'),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Text(
                    'Rate Your Experience',
                    style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was the service provided by ${_booking!.workerName?.split(' ').first ?? 'the worker'}?',
                    style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  _buildWorkerCard(_booking!),
                  const SizedBox(height: 40),

                  Text(
                    'Select Rating',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  _buildStarRating(),
                  _buildFieldErrors('score'),
                  const SizedBox(height: 40),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Write a Review',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 5,
                    style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Tell us about your experience...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                  _buildFieldErrors('comment'),
                  const SizedBox(height: 48),

                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _fieldErrors(String field) {
    final map = _serverErrors;
    if (map == null) return const [];
    final raw = map[field];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) return [raw];
    return const [];
  }

  Widget _buildFieldErrors(String field) {
    final errors = _fieldErrors(field);
    if (errors.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors
            .map((e) => Text(
                  e,
                  style: AppTypography.bodySmall.copyWith(color: colorScheme.error),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildWorkerCard(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: booking.workerPhotoUrl == null
                ? null
                : NetworkImage(booking.workerPhotoUrl!),
          ),
          const SizedBox(height: 16),
          Text(
            booking.workerName ?? 'Worker',
            style: AppTypography.headlineMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              booking.category.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
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
              color: isSelected ? Colors.amber : colorScheme.outlineVariant,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color bgColor = colorScheme.primary;
    String label = 'Submit Review';
    Widget icon = const SizedBox.shrink();

    if (_isSubmitting) {
      label = 'Submitting...';
      icon = Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2),
        ),
      );
    } else if (_isSuccess) {
      bgColor = colorScheme.primary;
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
              color: bgColor.withValues(alpha: 0.3),
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
                color: _isSuccess ? colorScheme.onPrimary : colorScheme.onPrimary,
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
