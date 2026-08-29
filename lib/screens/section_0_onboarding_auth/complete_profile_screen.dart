import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

/// Complete Profile Screen (0.5b)
/// 
/// For users who authenticated via Google. This screen collects the 
/// remaining required details (Mobile, Barangay) to complete the profile.
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
  final _nameController = TextEditingController(text: 'John Doe'); // Pre-filled from Google
  final _mobileController = TextEditingController();
  
  String? _selectedBarangay;
  bool _isLoading = false;

  final List<String> _barangays = [
    'Abachanan', 'Banlasan', 'Bongbong', 'Catoogan', 'Guinobatan',
    'Hinlayagan Centro', 'Hinlayagan Ilaud', 'Kinan-oan', 'La Victoria',
    'Mabuhay Cabigohan', 'Mahagbu', 'Manuel M. Roxas', 'Poblacion',
    'Puerto San Pedro', 'Quinicotogan', 'San Isidro', 'San Vicente',
    'Soledad', 'Tagum Norte', 'Tagum Sur',
  ];

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
      final result = await authRepository.updateProfile(
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        // Update local provider state
        await context.read<AuthProvider>().updateLocalProfile(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
        );

        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          context.go(authProvider.getHomeRoute());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFB), // Surface Cream
      body: Column(
        children: [
          // 1. Standardized Header
          const AppHeader(),

          // 2. Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text('Complete Profile', style: AppTypography.headlineLarge.copyWith(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      'Just a few more details needed to finish.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Profile Photo Placeholder
                    _buildProfilePhoto(),
                    
                    const SizedBox(height: 40),

                    // Full Name (Editable)
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Email (Google Provided - Disabled)
                    _buildDisabledEmailField('john.doe@gmail.com'),
                    const SizedBox(height: 20),

                    // Mobile Number
                    _buildMobileField(),
                    const SizedBox(height: 20),

                    // Barangay Dropdown (Custom Addition)
                    _buildBarangayDropdown(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // 3. Fixed Footer
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
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
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 50, color: AppColors.outline),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
    return TextFormField(
      controller: controller,
      style: AppTypography.bodyMedium,
      decoration: _getInputDecoration(label).copyWith(hintText: hint),
      validator: validator,
    );
  }

  Widget _buildDisabledEmailField(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Email Address', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
            Row(
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text('Provided by Google', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontSize: 10)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Text(email, style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
              const Spacer(),
              const Icon(Icons.lock_outline, size: 18, color: AppColors.outlineVariant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      style: AppTypography.bodyMedium,
      decoration: _getInputDecoration('Mobile Number').copyWith(
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Text('+63 ', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ),
        hintText: '9xx xxx xxxx',
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildBarangayDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBarangay,
      decoration: _getInputDecoration('Barangay'),
      items: _barangays.map((b) => DropdownMenuItem(
        value: b,
        child: Text(b, style: AppTypography.bodyMedium),
      )).toList(),
      onChanged: (val) => setState(() => _selectedBarangay = val),
      validator: (value) => value == null ? 'Please select your barangay' : null,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
      floatingLabelStyle: AppTypography.labelSmall.copyWith(color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}
