import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/barangay_model.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

/// Complete Profile Screen (0.5b)
class CompleteProfileScreen extends StatefulWidget {
  final String role;

  const CompleteProfileScreen({
    super.key,
    required this.role,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  
  String? _selectedBarangay;
  bool _isLoading = false;

  final List<String> _barangays = Barangay.trinidadBarangays.map((barangay) => barangay.name).toList();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController.text = authProvider.userName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacementNamed(context, authProvider.getHomeRoute());
      } else {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: colorScheme.error),
        );
      }
    } catch (e) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text('Complete Profile', style: AppTypography.headlineLarge.copyWith(fontSize: 28, color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Text(
                      'Just a few more details needed to finish.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    _buildProfilePhoto(),
                    
                    const SizedBox(height: 40),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildDisabledEmailField(authProvider.userEmail ?? 'user@gmail.com'),
                    const SizedBox(height: 20),

                    _buildMobileField(),
                    const SizedBox(height: 20),

                    _buildBarangayDropdown(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
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
              label: 'Finish Setup',
              showArrow: true,
              isLoading: _isLoading,
              onPressed: _handleCompleteProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 4),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.person, size: 50, color: colorScheme.outline),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 16, color: colorScheme.onPrimary),
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
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: _getInputDecoration(label).copyWith(hintText: hint),
      validator: validator,
    );
  }

  Widget _buildDisabledEmailField(String email) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Email Address', style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
            Row(
              children: [
                Icon(Icons.verified, size: 14, color: colorScheme.secondary),
                const SizedBox(width: 4),
                Text('Provided by Google', style: AppTypography.labelSmall.copyWith(color: colorScheme.secondary, fontSize: 10)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text(email, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant)),
              const Spacer(),
              Icon(Icons.lock_outline, size: 18, color: colorScheme.outlineVariant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileField() {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: _getInputDecoration('Mobile Number').copyWith(
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Text('+63 ', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        ),
        hintText: '9xx xxx xxxx',
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildBarangayDropdown() {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: _selectedBarangay,
      decoration: _getInputDecoration('Barangay'),
      items: _barangays.map((b) => DropdownMenuItem(
        value: b,
        child: Text(b, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface)),
      )).toList(),
      onChanged: (val) => setState(() => _selectedBarangay = val),
      validator: (value) => value == null ? 'Please select your barangay' : null,
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: AppTypography.labelSmall.copyWith(color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }
}
