import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _email;
  int? _selectedBarangayId;
  String? _selectedBarangayName;
  List<Map<String, dynamic>> _barangays = [];
  bool _barangaysLoading = true;

  String? _avatarPath;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.userName ?? '');
    _phoneController = TextEditingController(
      text: authProvider.userMobile ?? '',
    );
    _email = authProvider.userEmail ?? '';
    _selectedBarangayId = authProvider.userBarangayId;
    _selectedBarangayName = authProvider.userBarangay;
    _avatarPath = authProvider.userAvatar;
    _loadBarangays();
    // Hydrate from server if mobile not yet cached (login response often lacks it)
    if ((authProvider.userMobile == null || authProvider.userMobile!.isEmpty) &&
        authProvider.isAuthenticated) {
      authProvider.refreshProfile().then((_) {
        if (!mounted) return;
        setState(() {
          final refreshed = context.read<AuthProvider>();
          _phoneController.text = refreshed.userMobile ?? _phoneController.text;
          _nameController.text = refreshed.userName ?? _nameController.text;
          _email = refreshed.userEmail ?? _email;
          _selectedBarangayId =
              _safeBarangayId(refreshed.userBarangayId) ?? _selectedBarangayId;
          _selectedBarangayName =
              refreshed.userBarangay ?? _selectedBarangayName;
          _avatarPath = refreshed.userAvatar ?? _avatarPath;
        });
      });
    }
  }

  /// Safety guard: only keep a barangay id that actually exists in the loaded list.
  int? _safeBarangayId(int? id) {
    if (id == null) return null;
    return _barangays.any((b) => b['id'] == id) ? id : null;
  }

  Future<void> _loadBarangays() async {
    try {
      final res = await ApiClient.get('/barangays');
      final raw = res['data'];
      if (raw is List) {
        final list = raw
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
        if (!mounted) return;
        setState(() {
          _barangays = list;
          _barangaysLoading = false;
          _selectedBarangayId = _safeBarangayId(_selectedBarangayId);
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _barangaysLoading = false;
      // If loading failed, ensure we never keep an id that can't match an item
      _selectedBarangayId = _safeBarangayId(_selectedBarangayId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _avatarPath = image.path;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        barangayId: _selectedBarangayId,
        barangayName: _selectedBarangayName,
        avatarPath: _avatarPath,
      );

      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } catch (e) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
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
          const AppHeader(title: 'Edit Profile'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: 40),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Contact Number',
                      icon: Icons.phone_iphone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (!RegExp(r'^(\+63|0)9\d{9}$')
                            .hasMatch(val.replaceAll(' ', ''))) {
                          return 'Invalid format (e.g. 0917 123 4567)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildReadOnlyField(
                      label: 'Email Address (Non-editable)',
                      value: _email,
                      icon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 24),
                    _buildBarangayDropdown(),
                    const SizedBox(height: 48),
                    PrimaryButton(
                      label: 'Save Changes',
                      isLoading: _isLoading,
                      onPressed: _handleSave,
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

  Widget _buildPhotoSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Stack(
        children: [
          UserAvatar(
            name: _nameController.text,
            radius: 64,
            photoPath: _avatarPath == AppConstants.defaultAvatar
                ? null
                : _avatarPath,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.1,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarangayDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barangay',
          style: AppTypography.labelLarge.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (_barangaysLoading)
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          DropdownButtonFormField<int?>(
            key: const Key('barangay_dropdown'),
            initialValue: _selectedBarangayId,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.1,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
            ),
            hint: Text(
              'Select barangay',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            items: _barangays.map((b) {
              final name = b['name']?.toString() ?? '';
              return DropdownMenuItem<int?>(
                value: b['id'] is int
                    ? (b['id'] as int)
                    : int.tryParse(b['id']?.toString() ?? ''),
                child: Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBarangayId = value;
                _selectedBarangayName = value == null
                    ? null
                    : _barangays
                          .firstWhere(
                            (b) => b['id'] == value,
                            orElse: () => const {},
                          )['name']
                          ?.toString();
              });
            },
            validator: (value) =>
                value == null ? 'Please select your barangay' : null,
          ),
      ],
    );
  }
}
