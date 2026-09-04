import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

class AppTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;

  const AppTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: buildDecoration(
        context,
        label: label,
        hint: hint,
        prefixText: prefixText,
      ),
      validator: validator,
    );
  }

  static InputDecoration buildDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    String? prefixText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      labelStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: AppTypography.labelSmall.copyWith(color: colorScheme.primary),
      prefixStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }
}
