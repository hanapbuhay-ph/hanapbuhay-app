import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
        workerId: 'w1', 
        govIdPath: _govId!.path,
        brgyCertPath: _brgyCert!.path,
        selfiePath: _selfie!.path,
      );

      if (!mounted) return;
      final theme = Theme.of(context);

      if (result.success) {
        Navigator.pushReplacementNamed(context, AppRouter.verificationStatus);
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: theme.colorScheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: theme.colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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

          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'Step 1 of 3',
          style: AppTypography.labelLarge.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.33,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionalCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        'To verify your account, please upload clear photos of the following documents. This helps us maintain a safe community.',
        style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant, height: 1.6),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodyLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: file == null ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: file == null ? colorScheme.surfaceVariant.withValues(alpha: 0.1) : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: file == null ? colorScheme.outlineVariant.withValues(alpha: 0.5) : colorScheme.primary,
                style: BorderStyle.solid,
                width: file == null ? 2 : 1,
              ),
            ),
            child: file == null 
              ? Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colorScheme.surfaceVariant.withValues(alpha: 0.3), shape: BoxShape.circle),
                      child: Icon(Icons.photo_camera, color: colorScheme.onSurfaceVariant, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(hint, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(subHint, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: Text(actionLabel, style: TextStyle(color: colorScheme.onSurface)),
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
