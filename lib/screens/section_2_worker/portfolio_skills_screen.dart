import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/service_category_model.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/media/photo_tiles.dart';
import '../../widgets/layout/responsive_grid.dart';

class PortfolioSkillsScreen extends StatefulWidget {
  const PortfolioSkillsScreen({super.key});

  @override
  State<PortfolioSkillsScreen> createState() => _PortfolioSkillsScreenState();
}

class _PortfolioSkillsScreenState extends State<PortfolioSkillsScreen> {
  final ImagePicker _picker = ImagePicker();
  final _bioController = TextEditingController();

  Worker? _worker;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  List<String> _selectedCategories = [];
  List<ServiceCategory> _categories = [];
  List<String> _portfolioPaths = [];
  List<String?> _portfolioPhotoIds = [];
  String _currentBio = '';

  List<String> _initialCategories = [];
  List<String> _initialPortfolioPaths = [];
  List<String?> _initialPortfolioPhotoIds = [];
  String _initialBio = '';

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final authProvider = context.read<AuthProvider>();
    final workerProvider = context.read<WorkerProvider>();

    try {
      // GET /api/user does not currently include worker_profile; the worker
      // detail endpoint accepts either the profile ID or owning user ID.
      var profileId = authProvider.workerProfileId ?? authProvider.userId;
      if (profileId == null) {
        await authProvider.refreshProfile();
        profileId = authProvider.workerProfileId ?? authProvider.userId;
      }
      if (profileId == null) {
        throw StateError('Unable to determine your worker profile.');
      }

      final results = await Future.wait([
        workerProvider.getCategories(),
        workerProvider.getWorkerById(profileId),
      ]);
      final categories = results[0] as List<ServiceCategory>;
      final worker = results[1] as Worker?;
      if (worker == null) {
        throw StateError('Unable to load your worker profile.');
      }
      if (categories.isEmpty && worker.services.isNotEmpty) {
        throw StateError('Unable to load service categories. Please retry.');
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _worker = worker;
          _applyWorker(worker);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyWorker(Worker worker) {
    _selectedCategories = worker.serviceCategoryIds.isNotEmpty
        ? List.from(worker.serviceCategoryIds)
        : _categories
              .where((category) => worker.services.contains(category.label))
              .map((category) => category.id)
              .toList();
    _portfolioPaths = List.from(worker.portfolioImages);
    _portfolioPhotoIds = List<String?>.generate(
      _portfolioPaths.length,
      (index) => index < worker.portfolioPhotoIds.length
          ? worker.portfolioPhotoIds[index]
          : null,
    );
    _currentBio = worker.bio;
    _bioController.text = _currentBio;
    _initialCategories = List.from(_selectedCategories);
    _initialPortfolioPaths = List.from(_portfolioPaths);
    _initialPortfolioPhotoIds = List.from(_portfolioPhotoIds);
    _initialBio = _currentBio;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    if (_initialBio != _currentBio) return true;
    if (_initialCategories.length != _selectedCategories.length) return true;
    for (final cat in _selectedCategories) {
      if (!_initialCategories.contains(cat)) return true;
    }
    if (!_sameValues(_initialPortfolioPaths, _portfolioPaths)) return true;
    if (!_sameValues(_initialPortfolioPhotoIds, _portfolioPhotoIds)) {
      return true;
    }
    return false;
  }

  bool _sameValues<T>(List<T> first, List<T> second) =>
      first.length == second.length &&
      List.generate(
        first.length,
        (index) => first[index] == second[index],
      ).every((equal) => equal);

  Future<void> _addPhoto() async {
    if (_portfolioPaths.length >= 6) return;
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _portfolioPaths.add(image.path);
        _portfolioPhotoIds.add(null);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _portfolioPaths.removeAt(index);
      _portfolioPhotoIds.removeAt(index);
    });
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_isDirty) return;

    setState(() => _isSaving = true);

    try {
      final workerProvider = context.read<WorkerProvider>();
      final newPhotoPaths = <String>[];
      final keepPhotoIds = <String>[];
      for (var index = 0; index < _portfolioPaths.length; index++) {
        final photoId = _portfolioPhotoIds[index];
        if (photoId != null && photoId.isNotEmpty) {
          keepPhotoIds.add(photoId);
        } else if (!_portfolioPaths[index].startsWith('http')) {
          newPhotoPaths.add(_portfolioPaths[index]);
        }
      }
      final result = await workerProvider.updateWorkerProfile(
        workerId: _worker?.id ?? '',
        categoryIds: _selectedCategories,
        newPhotoPaths: newPhotoPaths,
        keepPhotoIds: keepPhotoIds,
        bio: _currentBio,
      );

      if (mounted) {
        final theme = Theme.of(context);
        final fieldErrors = result.errors?.values;
        final validationMessage = fieldErrors == null
            ? result.message
            : fieldErrors
                  .map(
                    (value) => value is List && value.isNotEmpty
                        ? value.first.toString()
                        : value.toString(),
                  )
                  .firstWhere(
                    (message) => message.isNotEmpty,
                    orElse: () => result.message,
                  );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationMessage),
            backgroundColor: result.success
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
        );
        if (result.success) {
          final refreshedWorker = await workerProvider.getWorkerById(
            _worker!.id,
          );
          if (refreshedWorker == null) {
            throw StateError('Profile was saved but could not be reloaded.');
          }
          if (mounted) {
            setState(() => _applyWorker(refreshedWorker));
          }
        }
        if (mounted) setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        setState(() => _isSaving = false);
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

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            const AppHeader(title: 'Portfolio & Skills'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _loadWorkerData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Portfolio & Skills'),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoriesCard(),
                      const SizedBox(height: 24),
                      _buildPortfolioCard(),
                      const SizedBox(height: 24),
                      _buildBioCard(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                _buildStickySaveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Categories',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _categories.map((cat) {
              final isSelected = _selectedCategories.contains(cat.id);
              return GestureDetector(
                onTap: () => _toggleCategory(cat.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check, size: 14, color: colorScheme.primary),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Past Work',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${_portfolioPaths.length} / 6 Max',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ResponsiveGrid(
            minimumItemWidth: 104,
            itemCount: _portfolioPaths.length < 6
                ? _portfolioPaths.length + 1
                : 6,
            itemBuilder: (context, index) {
              if (index == _portfolioPaths.length &&
                  _portfolioPaths.length < 6) {
                return _buildAddPhotoTile();
              }
              return _buildPhotoTile(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoTile() {
    return PhotoUploadTile(
      onTap: _addPhoto,
      label: 'Add',
      icon: Icons.add_circle_outline,
      borderRadius: 12,
    );
  }

  Widget _buildPhotoTile(int index) {
    return PhotoPreviewTile(
      path: _portfolioPaths[index],
      onRemove: () => _removePhoto(index),
      borderRadius: 12,
      removeIconSize: 12,
    );
  }

  Widget _buildBioCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Bio',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              TextFormField(
                controller: _bioController,
                maxLines: 5,
                maxLength:
                    1000, // backend allows 1000 chars (not 500 as docs say)
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
                onChanged: (val) => setState(() => _currentBio = val),
                decoration: InputDecoration(
                  hintText: 'Tell clients about your experience, specialties, and work ethic...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.1,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_currentBio.length}/1000',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickySaveButton() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: IgnorePointer(
        ignoring: !_isDirty || _isSaving,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isDirty ? 1.0 : 0.5,
          child: PrimaryButton(
            label: 'Save Changes',
            isLoading: _isSaving,
            onPressed: _handleSave,
          ),
        ),
      ),
    );
  }
}
