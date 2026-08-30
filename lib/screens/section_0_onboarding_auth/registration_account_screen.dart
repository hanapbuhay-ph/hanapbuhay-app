import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

/// Registration — Account Details Screen
/// 
/// Refactored to avoid "stacked" overlays. The footer is now part of the 
/// main layout Column, and the form area is scrollable in between.
class RegistrationAccountScreen extends StatefulWidget {
  final String role;

  const RegistrationAccountScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegistrationAccountScreen> createState() => _RegistrationAccountScreenState();
}

class _RegistrationAccountScreenState extends State<RegistrationAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedBarangay;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  Map<String, String> _fieldErrors = {};

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || !_agreeToTerms) return;

    setState(() {
      _isLoading = true;
      _fieldErrors = {};
    });

    try {
      final result = await context.read<AuthProvider>().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: widget.role,
        mobileNumber: _mobileController.text.trim(),
        barangay: _selectedBarangay!,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushNamed(context, '${AppRouter.verifyEmail}?email=${_emailController.text.trim()}');
      } else {
        if (result.errors != null) {
          setState(() {
            _fieldErrors = result.errors!.map((key, value) {
              if (value is List) return MapEntry(key, value.first.toString());
              return MapEntry(key, value.toString());
            });
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormValid = _agreeToTerms;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFDFB), // Surface Cream
      body: Column(
        children: [
          // 1. Standardized Header
          const AppHeader(),

          // 2. Scrollable Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Step 2 of 2',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role Confirmation Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Signing up as: ${widget.role[0].toUpperCase()}${widget.role.substring(1)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Change',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text('Account Details', style: AppTypography.headlineLarge.copyWith(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your details to complete registration.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    
                    const SizedBox(height: 40),

                    // Form Fields
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      errorText: _fieldErrors['name'],
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      hint: '09XX XXX XXXX',
                      keyboardType: TextInputType.phone,
                      errorText: _fieldErrors['mobile_number'],
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Barangay Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedBarangay,
                      decoration: _getInputDecoration('Barangay').copyWith(errorText: _fieldErrors['barangay']),
                      items: _barangays.map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b, style: AppTypography.bodyMedium),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedBarangay = val),
                      validator: (value) => value == null ? 'Please select your barangay' : null,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      errorText: _fieldErrors['email'],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: _obscurePassword,
                      errorText: _fieldErrors['password'],
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      errorText: _fieldErrors['confirm_password'],
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, size: 20),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24, width: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()..onTap = () => debugPrint('ToS'),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()..onTap = () => debugPrint('Privacy'),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // 3. Fixed Bottom Navigation (Not an overlay anymore)
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: const Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: 'Create Account',
                  showArrow: true,
                  isLoading: _isLoading,
                  onPressed: !isFormValid ? null : _handleRegister,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: AppTypography.bodySmall),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRouter.login),
                      child: Text(
                        'Log In',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? errorText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTypography.bodyMedium,
      decoration: _getInputDecoration(label).copyWith(
        hintText: hint,
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
      validator: validator,
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
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    );
  }
}
