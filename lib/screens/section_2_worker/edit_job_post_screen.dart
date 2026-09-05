import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploadingImages = false;
  bool _isUpdatingImages = false;
  JobPost? _originalPost;
  List<JobPostImage> _images = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _rateController = TextEditingController();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    final workerProvider = context.read<WorkerProvider>();
    JobPost? post;

    // Try dedicated post detail first
    try {
      final listing = await workerProvider.getJobPostDetail(widget.postId);
      if (listing != null) {
        post = listing.post;
      }
    } catch (_) {}

    // Fallback to current worker profile posts
    if (post == null) {
      final worker = await workerProvider.getWorkerById(AppConstants.mockWorkerId);
      if (worker != null) {
        try {
          post = worker.jobPosts.firstWhere((p) => p.id == widget.postId);
        } catch (_) {}
      }
    }

    if (post != null) {
      _originalPost = post;
      _titleController.text = post.title;
      _descriptionController.text = post.description;
      _rateController.text = post.startingRate.toString();
      _selectedCategory = post.category;
      _selectedRateType = post.rateType;
      _isAvailable = post.isAvailable;
      _images = List<JobPostImage>.from(post.images);
      _images.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
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
        images: _images,
      );

      final result = await workerProvider.updateJobPost(updatedPost);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImages() async {
    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 images allowed per job post.')),
      );
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (pickedFiles.isEmpty || !mounted) return;

    final remainingSlots = 10 - _images.length;
    final toUpload = pickedFiles.take(remainingSlots).map((x) => x.path).toList();

    if (pickedFiles.length > remainingSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limit is 10 images. Only uploading first $remainingSlots photo(s).',
          ),
        ),
      );
    }

    setState(() => _isUploadingImages = true);

    try {
      final updatedList = await context
          .read<WorkerProvider>()
          .uploadPostImages(widget.postId, toUpload);

      if (mounted) {
        setState(() {
          _images = List<JobPostImage>.from(updatedList)
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photos uploaded successfully.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photos: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _pickAndUploadImages,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }
  }

  Future<void> _deleteImage(JobPostImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo?'),
        content: const Text('Are you sure you want to remove this photo from your post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUpdatingImages = true);

    try {
      final result = await context
          .read<WorkerProvider>()
          .deletePostImage(widget.postId, image.id);

      if (mounted) {
        if (result.success) {
          setState(() {
            _images.removeWhere((img) => img.id == image.id);
            // Renumber remaining images
            for (var i = 0; i < _images.length; i++) {
              _images[i] = _images[i].copyWith(displayOrder: i);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo removed.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting photo: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingImages = false);
    }
  }

  Future<void> _moveImage(int fromIndex, int toIndex) async {
    if (toIndex < 0 || toIndex >= _images.length) return;

    final backup = List<JobPostImage>.from(_images);
    setState(() {
      final item = _images.removeAt(fromIndex);
      _images.insert(toIndex, item);
      for (var i = 0; i < _images.length; i++) {
        _images[i] = _images[i].copyWith(displayOrder: i);
      }
      _isUpdatingImages = true;
    });

    try {
      final imageIds = _images.map((img) => img.id).toList();
      final result = await context
          .read<WorkerProvider>()
          .reorderPostImages(widget.postId, imageIds);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order saved. First photo is your feed preview.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => _images = backup);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _images = backup);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering photos: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingImages = false);
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
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            SnackBar(
              content: const Text('Post deactivated'),
              backgroundColor: Colors.orange.shade700,
            ),
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
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Category',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _selectedCategory ?? '',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.lock_outline,
                            color: colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'Post Title',
                      hint: 'e.g. Expert Aircon Cleaning & Repair',
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Describe your service...',
                      maxLines: 4,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),

                    // Media Management Section
                    _buildMediaSection(colorScheme),
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
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<RateType>(
                            initialValue: _selectedRateType,
                            decoration: AppTextFormField.buildDecoration(
                              context,
                              label: 'Rate Type',
                            ),
                            items: RateType.values
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type.label),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedRateType = val!),
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
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available for Booking',
                                  style: AppTypography.labelLarge,
                                ),
                                Text(
                                  'Clients can see this post and send requests.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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
                          style: AppTypography.labelLarge.copyWith(
                            color: colorScheme.error,
                          ),
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

  Widget _buildMediaSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Photos (${_images.length}/10)',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'The first photo is shown as the card preview in search.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_isUploadingImages || _isUpdatingImages)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Photos List or Empty State
        if (_images.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No photos added yet',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add up to 10 photos of your work to attract more clients.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUploadingImages ? null : _pickAndUploadImages,
                  icon: const Icon(Icons.upload),
                  label: const Text('Add Photos'),
                ),
              ],
            ),
          ),
        ] else ...[
          // Reorderable Image Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _images.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final image = _images[index];
              final isCover = index == 0;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCover
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: isCover ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: image.thumbnailUrl ?? image.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 72,
                          height: 72,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Label / Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCover)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cover / Search Preview',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'Photo #${index + 1}',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            isCover
                                ? 'Visible first to clients'
                                : 'Shown in post detail',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Move Up/Down Controls
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: index > 0 && !_isUpdatingImages
                              ? () => _moveImage(index, index - 1)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: index < _images.length - 1 && !_isUpdatingImages
                              ? () => _moveImage(index, index + 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // Delete Button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 22,
                      ),
                      onPressed: _isUpdatingImages ? null : () => _deleteImage(image),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Add more button if < 10
          if (_images.length < 10)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploadingImages || _isUpdatingImages
                    ? null
                    : _pickAndUploadImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text('Add Photos (${10 - _images.length} slots left)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ],
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
