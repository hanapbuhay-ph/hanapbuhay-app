import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

class VerificationDocumentScreen extends StatefulWidget {
  const VerificationDocumentScreen({super.key});

  @override
  State<VerificationDocumentScreen> createState() => _VerificationDocumentScreenState();
}

class _VerificationDocumentScreenState extends State<VerificationDocumentScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _govId;
  XFile? _brgyCert;
  XFile? _selfie;
  bool _isSubmitting = false;

  bool get _isComplete => _govId != null && _brgyCert != null && _selfie != null;

  Future<void> _pickImage(String type, {ImageSource source = ImageSource.gallery}) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (type == 'govId') _govId = image;
        if (type == 'brgyCert') _brgyCert = image;
        if (type == 'selfie') _selfie = image;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_isComplete) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await context.read<WorkerProvider>().submitVerificationDocuments(
        workerId: 'w1', // Mock current worker
        govIdPath: _govId!.path,
        brgyCertPath: _brgyCert!.path,
        selfiePath: _selfie!.path,
      );

      if (mounted && result.success) {
        Navigator.pushReplacementNamed(context, AppRouter.verificationUnderReview);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(title: 'Verification'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildProgressIndicator(),
                  const SizedBox(height: 32),
                  _buildInstructionalCard(),
                  const SizedBox(height: 32),
                  
                  _buildUploadSection(
                    title: 'Valid Government ID',
                    icon: Icons.badge_outlined,
                    hint: 'Upload Government ID',
                    subHint: 'PNG, JPG up to 10MB',
                    file: _govId,
                    onTap: () => _pickImage('govId'),
                    onRemove: () => setState(() => _govId = null),
                  ),
                  const SizedBox(height: 24),

                  _buildUploadSection(
                    title: 'Barangay Certificate',
                    icon: Icons.description_outlined,
                    hint: 'Upload Certificate',
                    subHint: 'PNG, JPG up to 10MB',
                    file: _brgyCert,
                    onTap: () => _pickImage('brgyCert'),
                    onRemove: () => setState(() => _brgyCert = null),
                  ),
                  const SizedBox(height: 24),

                  _buildUploadSection(
                    title: 'Selfie holding ID',
                    icon: Icons.face_outlined,
                    hint: 'Upload Selfie',
                    subHint: 'Ensure face and ID are clear',
                    file: _selfie,
                    onTap: () => _pickImage('selfie', source: ImageSource.camera),
                    onRemove: () => setState(() => _selfie = null),
                    actionLabel: 'Take Photo',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Fixed Bottom Button
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
            ),
            child: PrimaryButton(
              label: 'Submit for Review',
              isLoading: _isSubmitting,
              onPressed: _isComplete ? _handleSubmit : null,
              showArrow: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Text(
          'Step 1 of 3',
          style: AppTypography.labelLarge.copyWith(color: AppColors.primaryContainer, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.33,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        'To verify your account, please upload clear photos of the following documents. This helps us maintain a safe community.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant, height: 1.6),
      ),
    );
  }

  Widget _buildUploadSection({
    required String title,
    required IconData icon,
    required String hint,
    required String subHint,
    XFile? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    String actionLabel = 'Choose File',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodyLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            Icon(icon, color: AppColors.outline, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: file == null ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: file == null ? AppColors.surfaceContainerLowest : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: file == null ? AppColors.outlineVariant : AppColors.primaryContainer,
                style: file == null ? BorderStyle.solid : BorderStyle.solid,
                width: file == null ? 2 : 1,
              ),
              // Simulating dashed border for empty state is hard in Flutter, using solid.
            ),
            child: file == null 
              ? Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: AppColors.surfaceContainerHigh, shape: BoxShape.circle),
                      child: const Icon(Icons.photo_camera, color: AppColors.onSurfaceVariant, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(hint, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subHint, style: AppTypography.bodySmall.copyWith(color: AppColors.outline)),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      child: Text(actionLabel, style: const TextStyle(color: AppColors.onSurface)),
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(file.path), height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white, size: 28),
                        onPressed: onRemove,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Tap thumbnail to replace', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }
}
