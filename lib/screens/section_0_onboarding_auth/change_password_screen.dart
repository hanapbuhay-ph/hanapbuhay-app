import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

/// Change Password Screen
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final isGoogle = authProvider.isGoogleLinked;
      
      final result = await authProvider.changePassword(
        currentPassword: isGoogle ? 'password123' : _currentPasswordController.text, // Mock current pass if Google
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      final colorScheme = Theme.of(context).colorScheme;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        Navigator.pop(context);
      } else {
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
    final authProvider = context.watch<AuthProvider>();
    final isGoogle = authProvider.isGoogleLinked;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(title: isGoogle ? 'Set a Password' : 'Change Password'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      isGoogle 
                        ? 'Set a password to use as an alternative login method to your Google account.'
                        : 'Your new password must be different from previous used passwords.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    
                    if (!isGoogle) ...[
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: 'Current Password',
                        obscure: _obscureCurrent,
                        toggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      hint: 'Min. 8 characters',
                      obscure: _obscureNew,
                      toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      obscure: _obscureConfirm,
                      toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (val) {
                        if (val != _newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
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
              label: 'Update Password',
              isLoading: _isLoading,
              onPressed: _handleChangePassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: AppTypography.labelSmall.copyWith(color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: colorScheme.onSurfaceVariant),
          onPressed: toggleObscure,
        ),
      ),
      validator: validator ?? (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
