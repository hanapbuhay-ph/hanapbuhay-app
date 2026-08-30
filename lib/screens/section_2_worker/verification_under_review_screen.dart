import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

class VerificationUnderReviewScreen extends StatelessWidget {
  const VerificationUnderReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(title: 'Verification', showBackButton: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: AppColors.surfaceContainerHigh.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        // Pulsing Icon Simulation
                        _buildStatusIcon(),
                        const SizedBox(height: 32),
                        
                        Text(
                          'Documents Under Review',
                          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
                            children: const [
                              TextSpan(text: 'Your documents are currently being processed. This usually takes '),
                              TextSpan(text: '1–3 business days', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Info Callout
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'We\'ll notify you once your verification is complete. In the meantime, you can still explore the app.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            child: PrimaryButton(
              label: 'Back to Home',
              showArrow: false,
              onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.workerHome),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Simulated pulse ring
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFFFDD80).withOpacity(0.2), // Light Amber
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFDD80).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pending_actions, size: 48, color: Color(0xFFCA8400)), // Amber/Tertiary
        ),
      ],
    );
  }
}
