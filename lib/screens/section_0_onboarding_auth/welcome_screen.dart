import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_typography.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _greeting = 'Welcome to';
  static const _brandName = 'HanapBuhay';
  static const _totalCharacters = 21;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _characterProgress(int index, double progress) {
    final start = index / _totalCharacters * 0.72;
    final end = start + 0.2;
    return Curves.easeOutCubic.transform(
      ((progress - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  Widget _buildAnimatedLine(
    String text, {
    required int startIndex,
    required TextStyle style,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < text.length; index++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _characterProgress(
                startIndex + index,
                _controller.value,
              );

              return Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - progress)),
                  child: child,
                ),
              );
            },
            child: Text(text[index], style: style),
          ),
      ],
    );
  }

  void _continue() {
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          children: [
            const Spacer(),
            Semantics(
              header: true,
              label: 'Welcome to HanapBuhay',
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedLine(
                        _greeting,
                        startIndex: 0,
                        style: AppTypography.headlineMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAnimatedLine(
                        _brandName,
                        startIndex: 11,
                        style: AppTypography.displayLarge.copyWith(
                          color: colorScheme.primary,
                          fontSize: 42,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.86, 1, curve: Curves.easeOut),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => IgnorePointer(
                  ignoring: !_controller.isCompleted,
                  child: child,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
