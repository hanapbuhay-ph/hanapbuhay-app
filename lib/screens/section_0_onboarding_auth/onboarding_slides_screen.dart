import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../core/routing/app_router.dart';

class OnboardingSlidesScreen extends StatefulWidget {
  const OnboardingSlidesScreen({super.key});

  @override
  State<OnboardingSlidesScreen> createState() => _OnboardingSlidesScreenState();
}

class _OnboardingSlidesScreenState extends State<OnboardingSlidesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: "What is HanapBuhay?",
      description: "Find skilled workers in your community — verified and trusted through your local barangay.",
      color: const Color(0xFFE8F5E9),
    ),
    OnboardingSlideData(
      title: "For Clients",
      description: "Book electricians, plumbers, tutors, cleaners, and more — right in your neighborhood.",
      color: const Color(0xFFF1F8E9),
    ),
    OnboardingSlideData(
      title: "For Workers",
      description: "Offer your skills, grow your reputation, and earn from what you do best.",
      color: const Color(0xFFF9FBE7),
    ),
    OnboardingSlideData(
      title: "Safe & Verified",
      description: "Every worker is barangay-document verified — so you always know who you're hiring.",
      color: const Color(0xFFFFFDE7),
    ),
  ];

  void _onFinish() {
    context.read<AuthProvider>().completeOnboarding();
    context.push(AppRouter.registerRole);
  }

  void _onSkip() {
    _onFinish();
  }

  void _onDotPressed(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Top 60%: Illustration Area (Swipes)
              Expanded(
                flex: 6,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _IllustrationPart(data: _slides[index]);
                  },
                ),
              ),
              
              // Bottom 40%: Static Card Area
              Expanded(
                flex: 4,
                child: _OnboardingCard(
                  data: _slides[_currentPage],
                  isLast: _currentPage == _slides.length - 1,
                  currentPage: _currentPage,
                  numPages: _slides.length,
                  onNext: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _onFinish();
                    }
                  },
                  onDotPressed: _onDotPressed,
                ),
              ),
            ],
          ),
          
          // Skip Button - overlaid on top
          if (_currentPage < _slides.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: _onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String description;
  final Color color;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.color,
  });
}

class _IllustrationPart extends StatelessWidget {
  final OnboardingSlideData data;

  const _IllustrationPart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_outlined,
                size: 100,
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '[ILLUSTRATION PLACEHOLDER]',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.outline,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final OnboardingSlideData data;
  final bool isLast;
  final int currentPage;
  final int numPages;
  final VoidCallback onNext;
  final ValueChanged<int> onDotPressed;

  const _OnboardingCard({
    required this.data,
    required this.isLast,
    required this.currentPage,
    required this.numPages,
    required this.onNext,
    required this.onDotPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDFB),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          // Option 2: Rising Info (Vertical Slide-Up)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1), // Rises slightly from the bottom
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey<int>(currentPage),
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(
                      fontSize: data.title.contains('HanapBuhay') ? 36 : 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.6,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation Section
          const SizedBox(height: 20),
          if (!isLast)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(numPages, (index) {
                    final isActive = index == currentPage;
                    return GestureDetector(
                      onTap: () => onDotPressed(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive 
                            ? AppColors.primaryContainer 
                            : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(numPages, (index) {
                    final isActive = index == currentPage;
                    return GestureDetector(
                      onTap: () => onDotPressed(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive 
                            ? AppColors.primaryContainer 
                            : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'Get Started',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
