import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

/// Registration — Account Details Screen
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
        
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: colorScheme.error),
        );
      }
    } catch (e) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e'), backgroundColor: colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormValid = _agreeToTerms;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                    const SizedBox(height: 16),
                    Text(
                      'Step 2 of 2',
                      style: AppTypography.labelLarge.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role Confirmation Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work_outline, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Signing up as: ${widget.role[0].toUpperCase()}${widget.role.substring(1)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Change',
                              style: AppTypography.labelSmall.copyWith(
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text('Account Details', style: AppTypography.headlineLarge.copyWith(fontSize: 28, color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your details to complete registration.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
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
                        child: Text(b, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedBarangay = val),
                      validator: (value) => value == null ? 'Please select your barangay' : null,
                      dropdownColor: colorScheme.surface,
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
                            activeColor: colorScheme.primary,
                            onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, AppRouter.termsOfService),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, AppRouter.privacyPolicy),
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

          // 3. Fixed Bottom Navigation
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
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
                    Text('Already have an account? ', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRouter.login),
                      child: Text(
                        'Log In',
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.primary,
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
      style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
      decoration: _getInputDecoration(label).copyWith(
        hintText: hint,
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
      validator: validator,
    );
  }

  InputDecoration _getInputDecoration(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: AppTypography.labelSmall.copyWith(color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error)),
    );
  }
}
