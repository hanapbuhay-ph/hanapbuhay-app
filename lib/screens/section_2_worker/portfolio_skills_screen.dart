import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/worker_bottom_nav.dart';
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

  // Local Edit State
  List<String> _selectedCategories = [];
  List<String> _portfolioPaths = []; // Can be URLs or local paths
  String _currentBio = '';

  // Baseline for dirty check
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
    // Assuming worker 'w1' for demo
    final worker = await context.read<WorkerProvider>().getWorkerById('w1');
    if (mounted && worker != null) {
      setState(() {
        _worker = worker;
        _selectedCategories = List.from(worker.services);
        _portfolioPaths = List.from(worker.portfolioImages);
        _currentBio = worker.bio;
        _bioController.text = worker.bio;

        // Set baseline
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
      final result = await context.read<WorkerProvider>().updateWorkerProfile(
        workerId: _worker!.id,
        categories: _selectedCategories,
        photoPaths: _portfolioPaths,
        bio: _currentBio,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.primary),
        );
        // Reset baseline
        setState(() {
          _initialCategories = List.from(_selectedCategories);
          _initialPortfolioPaths = List.from(_portfolioPaths);
          _initialBio = _currentBio;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portfolio & Skills', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 32),
                      
                      _buildCategoriesCard(),
                      const SizedBox(height: 24),
                      
                      _buildPortfolioCard(),
                      const SizedBox(height: 24),
                      
                      _buildBioCard(),
                      const SizedBox(height: 120), // Space for sticky button
                    ],
                  ),
                ),
                _buildStickySaveButton(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const WorkerBottomNav(currentIndex: 4), // Profile tab
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 16),
            const Text(
              'HanapBuhay',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
            const Spacer(),
            CircleAvatar(radius: 16, backgroundImage: NetworkImage(_worker?.avatarUrl ?? '')),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service Categories', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
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
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check, size: 14, color: AppColors.primary),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Past Work', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(
                '${_portfolioPaths.length} / 6 Max',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
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
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professional Bio', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          Stack(
            children: [
              TextFormField(
                controller: _bioController,
                maxLines: 5,
                maxLength: 500,
                style: AppTypography.bodyMedium,
                onChanged: (val) => setState(() => _currentBio = val),
                decoration: InputDecoration(
                  hintText: 'Tell clients about your experience, specialties, and work ethic...',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  counterText: '', // Using custom counter
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${_currentBio.length}/500',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
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
