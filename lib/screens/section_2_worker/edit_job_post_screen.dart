import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/job_post_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/forms/app_text_form_field.dart';

class EditJobPostScreen extends StatefulWidget {
  final String postId;

  const EditJobPostScreen({
    super.key,
    required this.postId,
  });

  @override
  State<EditJobPostScreen> createState() => _EditJobPostScreenState();
}

class _EditJobPostScreenState extends State<EditJobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _rateController;

  String? _selectedCategory;
  RateType _selectedRateType = RateType.perHour;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isInitializing = true;
  JobPost? _originalPost;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _rateController = TextEditingController();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    // In a real app, we might fetch the specific post or get it from the worker's list in provider
    // For now, let's assume we can find it in the current worker's profile
    final workerProvider = context.read<WorkerProvider>();
    final worker = await workerProvider.getWorkerById(AppConstants.mockWorkerId);
    
    if (worker != null) {
      try {
        final post = worker.jobPosts.firstWhere((p) => p.id == widget.postId);
        _originalPost = post;
        _titleController.text = post.title;
        _descriptionController.text = post.description;
        _rateController.text = post.startingRate.toString();
        _selectedCategory = post.category;
        _selectedRateType = post.rateType;
        _isAvailable = post.isAvailable;
      } catch (e) {
        // Post not found
      }
    }
    
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final workerProvider = context.read<WorkerProvider>();
      
      final updatedPost = _originalPost!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startingRate: double.tryParse(_rateController.text) ?? 0.0,
        rateType: _selectedRateType,
        isAvailable: _isAvailable,
      );

      final result = await workerProvider.updateJobPost(updatedPost);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message), backgroundColor: Theme.of(context).colorScheme.primary),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeactivate() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Deactivate this post?', style: AppTypography.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Your post will be hidden from the client feed. You can reactivate it anytime.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Deactivate',
              onPressed: () => Navigator.pop(context, true),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Keep Active'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final result = await context.read<WorkerProvider>().deleteJobPost(widget.postId);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Post deactivated'), backgroundColor: Colors.orange.shade700),
          );
          Navigator.pop(context);
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_originalPost == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Post')),
        body: const Center(child: Text('Post not found')),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Edit Post'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category (Read-only in Edit)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Service Category', style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
                                Text(_selectedCategory ?? '', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'Post Title',
                      hint: 'e.g. Expert Aircon Cleaning & Repair',
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Describe your service...',
                      maxLines: 4,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),

                    const Text('Pricing', style: AppTypography.headlineSmall),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _rateController,
                            label: 'Starting Rate',
                            hint: '0.00',
                            keyboardType: TextInputType.number,
                            prefixText: '₱ ',
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<RateType>(
                            initialValue: _selectedRateType,
                            decoration: AppTextFormField.buildDecoration(context, label: 'Rate Type'),
                            items: RateType.values.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedRateType = val!),
                            dropdownColor: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Availability Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available for Booking', style: AppTypography.labelLarge),
                                Text(
                                  'Clients can see this post and send requests.',
                                  style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (val) => setState(() => _isAvailable = val),
                            activeThumbColor: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Danger Zone
                    Center(
                      child: TextButton(
                        onPressed: _handleDeactivate,
                        child: Text(
                          'Deactivate This Post',
                          style: AppTypography.labelLarge.copyWith(color: colorScheme.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: PrimaryButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return AppTextFormField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      keyboardType: keyboardType,
      prefixText: prefixText,
      validator: validator,
    );
  }
}
