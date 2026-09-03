import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/booking_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/report_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

class FileReportScreen extends StatefulWidget {
  final String bookingId;

  const FileReportScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<FileReportScreen> createState() => _FileReportScreenState();
}

class _FileReportScreenState extends State<FileReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  Booking? _booking;
  Worker? _worker;
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  String? _selectedReason;
  final List<XFile> _selectedPhotos = [];

  final List<String> _reasons = [
    'No-show',
    'Unsatisfactory work',
    'Misconduct',
    'Other'
  ];

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
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 3) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedPhotos.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<ReportProvider>().submitReport(
        bookingId: widget.bookingId,
        workerId: _worker!.id,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        photoPaths: _selectedPhotos.map((p) => p.path).toList(),
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.primary),
        );
        Navigator.pushReplacementNamed(context, AppRouter.reportStatus);
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
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoadingData) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    if (_booking == null || _worker == null) {
      return const Scaffold(body: Center(child: Text('Booking details not found')));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(title: 'File a Report'),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context Card
                    _buildContextCard(_booking!, _worker!),
                    const SizedBox(height: 32),

                    // Reason Dropdown
                    Text('Reason for Report', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedReason,
                      decoration: _getInputDecoration('Select a reason'),
                      items: _reasons.map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r, style: AppTypography.bodyMedium),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedReason = val),
                      validator: (val) => val == null ? 'Please select a reason' : null,
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text('Description', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      style: AppTypography.bodyMedium,
                      decoration: _getInputDecoration('Details').copyWith(
                        hintText: 'Please describe the issue in detail...',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please provide a description' : null,
                    ),
                    const SizedBox(height: 32),

                    // Photo Evidence
                    Text('Attach Photo Evidence (Optional)', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Upload up to 3 photos to support your report.',
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _buildPhotoGrid(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Bottom Bar
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: PrimaryButton(
              label: 'Submit Report',
              showArrow: true,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard(Booking booking, Worker worker) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Details Regarding:',
            style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(worker.avatarUrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
                    Text(worker.specialty, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildTagChip(booking.category),
              _buildTagChip('${booking.date.day}/${booking.date.month}/${booking.date.year}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _selectedPhotos.length < 3 ? _selectedPhotos.length + 1 : 3,
      itemBuilder: (context, index) {
        if (index == _selectedPhotos.length && _selectedPhotos.length < 3) {
          return _buildUploadTile();
        }
        return _buildPhotoTile(index);
      },
    );
  }

  Widget _buildUploadTile() {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid), // In reality Flutter doesn't support dashed borders easily out of box, usually custom painter needed. Using solid for now.
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
            SizedBox(height: 4),
            Text('Add Photo', style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(_selectedPhotos[index].path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}
