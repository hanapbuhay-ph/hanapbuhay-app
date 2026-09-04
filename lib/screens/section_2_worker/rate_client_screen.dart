import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/navigation/app_header.dart';

class RateClientScreen extends StatefulWidget {
  final String bookingId;

  const RateClientScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<RateClientScreen> createState() => _RateClientScreenState();
}

class _RateClientScreenState extends State<RateClientScreen> {
  Booking? _booking;
  bool _isLoading = true;
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _feedbackWords = [
    "Very Poor",
    "Poor",
    "Okay",
    "Good",
    "Excellent!"
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final booking = await context.read<BookingProvider>().getBookingById(widget.bookingId);
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
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<BookingProvider>().submitClientRating(
        bookingId: widget.bookingId,
        clientId: _booking!.clientId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: Text('Booking details not found')),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Rate Client'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Client Summary
                  _buildClientSummary(),
                  const SizedBox(height: 32),

                  // Rating Card
                  _buildRatingCard(),
                  const SizedBox(height: 32),

                  // Review Input
                  _buildReviewInput(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildClientSummary() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2),
          ),
          child: const ClipOval(
            child: Image(
              image: NetworkImage('https://i.pravatar.cc/150?u=client123'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Maria Santos', 
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          _booking!.category,
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'How was your experience?',
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 20, 
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
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
                    color: isSelected ? const Color(0xFFFFB957) : colorScheme.outlineVariant,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          if (_selectedRating > 0)
            Text(
              _feedbackWords[_selectedRating - 1],
              style: AppTypography.labelLarge.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewInput() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write a Review (Optional)',
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _commentController,
          maxLines: 4,
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Share your experience working with Maria...',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isEnabled = _selectedRating > 0 && !_isSubmitting;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            disabledForegroundColor: colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: isEnabled ? 2 : 0,
          ),
          child: _isSubmitting
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
              : const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
