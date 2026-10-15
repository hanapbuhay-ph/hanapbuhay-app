import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

enum _DocumentUploadState { idle, uploading, complete, failed }

class VerificationDocumentScreen extends StatefulWidget {
  const VerificationDocumentScreen({super.key});

  @override
  State<VerificationDocumentScreen> createState() =>
      _VerificationDocumentScreenState();
}

class _VerificationDocumentScreenState
    extends State<VerificationDocumentScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _govIdFront;
  XFile? _govIdBack;
  XFile? _brgyCert;
  XFile? _selfie;
  XFile? _skillCert;
  bool _isSubmitting = false;
  final Map<String, _DocumentUploadState> _uploadStates = {
    'govIdFront': _DocumentUploadState.idle,
    'govIdBack': _DocumentUploadState.idle,
    'brgyCert': _DocumentUploadState.idle,
    'selfie': _DocumentUploadState.idle,
    'skillCert': _DocumentUploadState.idle,
  };
  String? _uploadError;
  // Fix 3 — inline 422 validation errors per field
  Map<String, dynamic> _fieldErrors = {};

  bool get _isComplete =>
      _govIdFront != null &&
      _govIdBack != null &&
      _brgyCert != null &&
      _selfie != null;

  double get _documentProgress {
    if (_isSubmitting) return 1.0;
    var progress = 0.0;
    if (_govIdFront != null) progress += 1 / 6;
    if (_govIdBack != null) progress += 1 / 6;
    if (_brgyCert != null) progress += 1 / 3;
    if (_selfie != null) progress += 1 / 3;
    return progress;
  }

  int get _currentStep {
    if (_isSubmitting || _isComplete) return 3;
    if (_govIdFront == null || _govIdBack == null) return 1;
    if (_brgyCert == null) return 2;
    return 3;
  }

  Future<void> _pickImage(
    String type, {
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_isSubmitting) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (type == 'govIdFront') _govIdFront = image;
        if (type == 'govIdBack') _govIdBack = image;
        if (type == 'brgyCert') _brgyCert = image;
        if (type == 'selfie') _selfie = image;
        if (type == 'skillCert') _skillCert = image;
        // Clear field error for this slot on new pick
        _fieldErrors.remove(_fieldErrorKey(type));
      });
    }
  }

  String _fieldErrorKey(String type) {
    switch (type) {
      case 'govIdFront':
        return 'government_id_front';
      case 'govIdBack':
        return 'government_id_back';
      case 'brgyCert':
        return 'barangay_certificate';
      case 'selfie':
        return 'selfie_with_id';
      case 'skillCert':
        return 'skill_certificate';
      default:
        return type;
    }
  }

  String? _fieldError(String type) {
    final key = _fieldErrorKey(type);
    final val = _fieldErrors[key];
    if (val is List && val.isNotEmpty) return val.first.toString();
    if (val is String) return val;
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_isComplete || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _uploadError = null;
      _fieldErrors = {};
      for (final type in _uploadStates.keys) {
        _uploadStates[type] = _DocumentUploadState.uploading;
      }
    });

    try {
      // POST /api/worker/verification/submit — multipart/form-data
      // Required: government_id_front, government_id_back, barangay_certificate,
      // selfie_with_id (images, max 5MB)
      // Optional: skill_certificate
      // Returns 422 if already pending or approved.
      // Note: success message is short: "Documents submitted for review." (not the longer docs version)
      final result = await context
          .read<WorkerProvider>()
          .submitVerificationDocuments(
            govIdFrontPath: _govIdFront!.path,
            govIdBackPath: _govIdBack!.path,
            brgyCertPath: _brgyCert!.path,
            selfiePath: _selfie!.path,
            skillCertPath: _skillCert?.path,
          );

      if (!mounted) return;
      final theme = Theme.of(context);

      if (result.success) {
        setState(() {
          for (final type in _uploadStates.keys) {
            _uploadStates[type] = _DocumentUploadState.complete;
          }
        });
        Navigator.pushReplacementNamed(context, AppRouter.verificationStatus);
      } else {
        // Fix 3 — extract inline 422 field errors if present
        final errors = result.errors ?? {};
        setState(() {
          _isSubmitting = false;
          _uploadError = result.message;
          _fieldErrors = errors;
          for (final type in _uploadStates.keys) {
            _uploadStates[type] = _DocumentUploadState.failed;
          }
        });
        // Show aggregated error snackbar if no field-specific errors
        if (errors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        setState(() {
          _isSubmitting = false;
          _uploadError = 'Error: $e';
          _fieldErrors = {};
          for (final type in _uploadStates.keys) {
            _uploadStates[type] = _DocumentUploadState.failed;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Verification'),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildProgressIndicator(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        _buildInstructionalCard(),
                        const SizedBox(height: 32),

                        _buildUploadSection(
                          title: 'Valid Government ID — Front',
                          icon: Icons.badge_outlined,
                          hint: 'Upload Front of ID',
                          subHint: 'PNG, JPG up to 5MB',
                          file: _govIdFront,
                          uploadState: _uploadStates['govIdFront']!,
                          onTap: () => _pickImage('govIdFront'),
                          onRemove: () => _removeImage('govIdFront'),
                          fieldError: _fieldError('govIdFront'),
                        ),
                        const SizedBox(height: 24),

                        _buildUploadSection(
                          title: 'Valid Government ID — Back',
                          icon: Icons.badge_outlined,
                          hint: 'Upload Back of ID',
                          subHint: 'PNG, JPG up to 5MB',
                          file: _govIdBack,
                          uploadState: _uploadStates['govIdBack']!,
                          onTap: () => _pickImage('govIdBack'),
                          onRemove: () => _removeImage('govIdBack'),
                          fieldError: _fieldError('govIdBack'),
                        ),
                        const SizedBox(height: 24),

                        _buildUploadSection(
                          title: 'Barangay Certificate',
                          icon: Icons.description_outlined,
                          hint: 'Upload Certificate',
                          subHint: 'PNG, JPG up to 5MB',
                          file: _brgyCert,
                          uploadState: _uploadStates['brgyCert']!,
                          onTap: () => _pickImage('brgyCert'),
                          onRemove: () => _removeImage('brgyCert'),
                          fieldError: _fieldError('brgyCert'),
                        ),
                        const SizedBox(height: 24),

                        _buildUploadSection(
                          title: 'Selfie holding ID',
                          icon: Icons.face_outlined,
                          hint: 'Upload Selfie',
                          subHint: 'Ensure face and ID are clear',
                          file: _selfie,
                          uploadState: _uploadStates['selfie']!,
                          onTap: () =>
                              _pickImage('selfie', source: ImageSource.camera),
                          onRemove: () => _removeImage('selfie'),
                          actionLabel: 'Take Photo',
                          fieldError: _fieldError('selfie'),
                        ),
                        const SizedBox(height: 24),

                        // Optional skill certificate
                        _buildUploadSection(
                          title: 'Skill Certificate (Optional)',
                          icon: Icons.workspace_premium_outlined,
                          hint: 'Upload Certificate',
                          subHint: 'PNG, JPG up to 5MB — optional',
                          file: _skillCert,
                          uploadState: _uploadStates['skillCert']!,
                          onTap: () => _pickImage('skillCert'),
                          onRemove: () => _removeImage('skillCert'),
                          fieldError: _fieldError('skillCert'),
                          isRequired: false,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_uploadError != null) ...[
                  Text(
                    _uploadError!,
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
                PrimaryButton(
                  label: 'Submit for Review',
                  isLoading: _isSubmitting,
                  onPressed: _isComplete ? _handleSubmit : null,
                  showArrow: true,
                ),
              ],
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
          'Step $_currentStep of 3',
          style: AppTypography.labelLarge.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _documentProgress == 0 ? 0.01 : _documentProgress,
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'To verify your account, please upload clear photos of the following documents. This helps us maintain a safe community.',
        style: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildUploadSection({
    required String title,
    required IconData icon,
    required String hint,
    required String subHint,
    XFile? file,
    required _DocumentUploadState uploadState,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    String actionLabel = 'Choose File',
    String? fieldError,
    bool isRequired = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (!isRequired) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'optional',
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: file == null && !_isSubmitting ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: file == null
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: fieldError != null
                    ? colorScheme.error
                    : file == null
                    ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                    : colorScheme.primary,
                width: file == null ? 2 : 1,
              ),
            ),
            child: file == null
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.photo_camera,
                          color: colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hint,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subHint,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : onTap,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(color: colorScheme.outline),
                        ),
                        child: Text(
                          actionLabel,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(file.path),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: colorScheme.onPrimary,
                            size: 28,
                          ),
                          onPressed: _isSubmitting ? null : onRemove,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.scrim.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Tap thumbnail to replace',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        // Fix 3 — inline field error text below each upload section
        if (fieldError != null) ...[
          const SizedBox(height: 6),
          Text(
            fieldError,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
        ],
        if (uploadState == _DocumentUploadState.uploading)
          _buildUploadProgress(colorScheme),
        if (uploadState == _DocumentUploadState.complete)
          _buildUploadStatus('Upload complete', colorScheme.primary),
        if (uploadState == _DocumentUploadState.failed && fieldError == null)
          _buildUploadStatus('Upload failed. Try again.', colorScheme.error),
      ],
    );
  }

  Widget _buildUploadProgress(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(child: LinearProgressIndicator(color: colorScheme.primary)),
          const SizedBox(width: 12),
          Text(
            'Uploading...',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStatus(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            label == 'Upload complete'
                ? Icons.check_circle
                : Icons.error_outline,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _removeImage(String type) {
    if (_isSubmitting) return;
    setState(() {
      if (type == 'govIdFront') _govIdFront = null;
      if (type == 'govIdBack') _govIdBack = null;
      if (type == 'brgyCert') _brgyCert = null;
      if (type == 'selfie') _selfie = null;
      if (type == 'skillCert') _skillCert = null;
      _uploadStates[type] = _DocumentUploadState.idle;
      _uploadError = null;
    });
  }
}
