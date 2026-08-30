import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../core/routing/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _initialize();
  }

  Future<void> _initialize() async {
    // 1.5s minimum display time + logic check
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      context.read<AuthProvider>().checkInitialState(),
    ]);

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Navigation logic
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, authProvider.getHomeRoute());
    } else if (authProvider.hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.onboarding);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Radial Glow Effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppColors.primaryContainer.withOpacity(0.2),
                    AppColors.background.withOpacity(0.0),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // Main Content
          Center(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.9, end: 1.0).animate(_pulseController),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Container
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24), // rounded-xl equivalent
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/screen.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // App Name
                  Text(
                    'HanapBuhay',
                    style: AppTypography.displayLarge,
                  ),
                  
                  // Tagline
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Connecting talent with opportunity.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading Indicator at bottom
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Column(
              children: [
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.primaryContainer,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'INITIALIZING...',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
