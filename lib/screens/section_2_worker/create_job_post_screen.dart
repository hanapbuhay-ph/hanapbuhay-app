import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/worker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/job_post_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/forms/app_text_form_field.dart';

class CreateJobPostScreen extends StatefulWidget {
  const CreateJobPostScreen({super.key});

  @override
  State<CreateJobPostScreen> createState() => _CreateJobPostScreenState();
}

class _CreateJobPostScreenState extends State<CreateJobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController();

  String? _selectedCategory;
  RateType _selectedRateType = RateType.perHour;
  bool _isAvailable = true;
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  late Future<List<ServiceCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = context.read<WorkerProvider>().getCategories();
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
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final workerProvider = context.read<WorkerProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // In a real app, we'd get the worker ID from the auth state
      final workerId = authProvider.userId ?? AppConstants.mockWorkerId;

      final newPost = JobPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workerId: workerId,
        category: _selectedCategory!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startingRate: double.tryParse(_rateController.text) ?? 0.0,
        rateType: _selectedRateType,
        isAvailable: _isAvailable,
        imageUrls: _selectedImages.map((image) => image.path).toList(),
      );

      final result = await workerProvider.createJobPost(newPost);

      if (result.success && _selectedImages.isNotEmpty) {
        try {
          await workerProvider.uploadPostImages(
            newPost.id,
            _selectedImages.map((image) => image.path).toList(),
          );
        } catch (_) {}
      }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'New Job Post'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Post Details', style: AppTypography.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Describe the service you want to offer to clients in Trinidad.',
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),

                    // Category Dropdown
                    FutureBuilder<List<ServiceCategory>>(
                      future: _categoriesFuture,
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: AppTextFormField.buildDecoration(context, label: 'Service Category'),
                          items: categories.map((c) => DropdownMenuItem(
                            value: c.label,
                            child: Text(c.label),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val),
                          validator: (val) => val == null ? 'Required' : null,
                          dropdownColor: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

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
                      hint: 'Describe your experience, tools, and what is included...',
                      maxLines: 4,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildImagePicker(),
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
              label: 'Create Post',
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

  Widget _buildImagePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Photos (optional)', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Add up to 10 photos to show clients your work.', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (_selectedImages.length < 10 ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add photos'),
                );
              }
              final image = _selectedImages[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FutureBuilder(
                      future: image.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(width: 92, height: 92, color: colorScheme.surfaceContainerHighest, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                        }
                        return Image.memory(snapshot.data!, width: 92, height: 92, fit: BoxFit.cover);
                      },
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: InkWell(
                      onTap: () => setState(() => _selectedImages.removeAt(index)),
                      child: const CircleAvatar(radius: 12, child: Icon(Icons.close, size: 14)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
    if (!mounted || images.isEmpty) return;
    setState(() {
      _selectedImages.addAll(images.take(10 - _selectedImages.length));
    });
  }
}
