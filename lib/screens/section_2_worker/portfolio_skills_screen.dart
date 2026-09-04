import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

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

  List<String> _selectedCategories = [];
  List<String> _portfolioPaths = []; 
  String _currentBio = '';

  List<String> _initialCategories = [];
  List<String> _initialPortfolioPaths = [];
  String _initialBio = '';

  final List<String> _allCategories = [
    'Plumbing', 'Electrical', 'Tutoring', 'Cleaning', 
    'Laundry', 'Gardening', 'Carpentry', 'General Repairs'
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    final worker = await context.read<WorkerProvider>().getWorkerById('w1');
    if (mounted && worker != null) {
      setState(() {
        _worker = worker;
        _selectedCategories = List.from(worker.services);
        _portfolioPaths = List.from(worker.portfolioImages);
        _currentBio = worker.bio;
        _bioController.text = worker.bio;

        _initialCategories = List.from(_selectedCategories);
        _initialPortfolioPaths = List.from(_portfolioPaths);
        _initialBio = _currentBio;

        _isLoading = false;
      });
    }
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
    if (_initialPortfolioPaths.length != _portfolioPaths.length) return true;
    for (int i = 0; i < _portfolioPaths.length; i++) {
      if (_initialPortfolioPaths[i] != _portfolioPaths[i]) return true;
    }
    return false;
  }

  Future<void> _addPhoto() async {
    if (_portfolioPaths.length >= 6) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _portfolioPaths.add(image.path);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _portfolioPaths.removeAt(index);
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_isDirty) return;

    setState(() => _isSaving = true);

    try {
      final theme = Theme.of(context);
      final result = await context.read<WorkerProvider>().updateWorkerProfile(
        workerId: _worker!.id,
        categories: _selectedCategories,
        photoPaths: _portfolioPaths,
        bio: _currentBio,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: theme.colorScheme.primary),
        );
        setState(() {
          _initialCategories = List.from(_selectedCategories);
          _initialPortfolioPaths = List.from(_portfolioPaths);
          _initialBio = _currentBio;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        setState(() => _isSaving = false);
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

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(title: 'Portfolio & Skills'),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service Categories', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
              Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _allCategories.map((cat) {
              final isSelected = _selectedCategories.contains(cat);
              return GestureDetector(
                onTap: () => _toggleCategory(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Past Work', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
              Text(
                '${_portfolioPaths.length} / 6 Max',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _portfolioPaths.length < 6 ? _portfolioPaths.length + 1 : 6,
            itemBuilder: (context, index) {
              if (index == _portfolioPaths.length && _portfolioPaths.length < 6) {
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
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index) {
    final path = _portfolioPaths[index];
    final isUrl = path.startsWith('http');

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isUrl 
              ? Image.network(path, fit: BoxFit.cover)
              : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: colorScheme.shadow.withValues(alpha: 0.7), shape: BoxShape.circle),
              child: Icon(Icons.close, size: 12, color: colorScheme.onPrimary),
            ),
          ),
        ),
      ],
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
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professional Bio', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          Stack(
            children: [
              TextFormField(
                controller: _bioController,
                maxLines: 5,
                maxLength: 500,
                style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
                onChanged: (val) => setState(() => _currentBio = val),
                decoration: InputDecoration(
                  hintText: 'Tell clients about your experience, specialties, and work ethic...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  counterText: '', 
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${_currentBio.length}/500',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
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
