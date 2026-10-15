import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

/// Email Verification Screen (0.5)
///
/// Users enter a 6-digit OTP sent to their email to complete registration.
class EmailVerificationScreen extends StatefulWidget {
  static const otpValiditySeconds = 5 * 60;

  final String email;
  final bool isLoginChallenge;
  final int otpExpiresInSeconds;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.isLoginChallenge = false,
    this.otpExpiresInSeconds = otpValiditySeconds,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _timer;
  Timer? _expiryTimer;
  int _secondsRemaining = 59;
  int _otpSecondsRemaining = EmailVerificationScreen.otpValiditySeconds;
  bool _canResend = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startExpiryTimer(widget.otpExpiresInSeconds);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 59;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  void _startExpiryTimer(int seconds) {
    _expiryTimer?.cancel();
    setState(() => _otpSecondsRemaining = seconds);
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _otpSecondsRemaining = 0);
        return;
      }
      setState(() => _otpSecondsRemaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _expiryTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    if (_otp.length < 6 || _otpSecondsRemaining <= 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = widget.isLoginChallenge
          ? await authProvider.verifyLoginOtp(widget.email, _otp)
          : await authProvider.verifyOtp(widget.email, _otp);

      if (!mounted) return;

      if (result.success) {
        if (!mounted) return;
        if (widget.isLoginChallenge) {
          final user = result.data?['user'];
          final hasRole =
              user is Map &&
              user['role'] != null &&
              user['role'].toString().isNotEmpty &&
              user['role'].toString() != 'null';
          Navigator.pushReplacementNamed(
            context,
            hasRole ? authProvider.getHomeRoute() : AppRouter.completeProfile,
          );
        } else {
          Navigator.pushReplacementNamed(context, authProvider.getHomeRoute());
        }
      } else {
        _handleError(result.message);
      }
    } catch (e) {
      _handleError('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleError(String message) {
    setState(() => _errorMessage = message);
    _shakeController.forward(from: 0);
    HapticFeedback.vibrate();

    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    _startTimer();
    try {
      final authProvider = context.read<AuthProvider>();
      final result = widget.isLoginChallenge
          ? await authProvider.resendLoginOtp(widget.email)
          : await authProvider.resendOtp(widget.email);
      if (!result.success && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }
      if (result.success && mounted) {
        final expiresIn = int.tryParse(
          result.data?['otp_expires_in_seconds']?.toString() ?? '',
        );
        if (expiresIn != null && expiresIn > 0) {
          _startExpiryTimer(expiresIn);
        }
      }
    } catch (_) {
      // Resend is best-effort; timer already reset so user can try again.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('A new code has been sent.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    widget.isLoginChallenge
                        ? 'Verify your login'
                        : 'Verify your email',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(
                      fontSize: 28,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: widget.isLoginChallenge
                              ? 'We sent a verification code to\n'
                              : 'We sent a verification code to your email address\n',
                        ),
                        TextSpan(
                          text: widget.email,
                          style: AppTypography.labelLarge.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => _buildOtpBox(index),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    _otpSecondsRemaining > 0
                        ? 'Code expires in ${(_otpSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_otpSecondsRemaining % 60).toString().padLeft(2, '0')}'
                        : 'This code has expired. Request a new one.',
                    style: AppTypography.bodySmall.copyWith(
                      color: _otpSecondsRemaining > 0
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  Text(
                    _canResend
                        ? "Didn't receive the code?"
                        : "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: _canResend ? _handleResend : null,
                    child: Text(
                      'Resend Code',
                      style: AppTypography.labelLarge.copyWith(
                        color: _canResend
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: PrimaryButton(
              label: 'Verify',
              showArrow: true,
              isLoading: _isLoading,
              onPressed: _otp.length == 6 && _otpSecondsRemaining > 0
                  ? _handleVerify
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaste(String pasted) {
    final digits = pasted.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final toFill = digits.length > 6 ? digits.substring(0, 6) : digits;
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = i < toFill.length ? toFill[i] : '';
    }
    setState(() {});
    if (toFill.length == 6) {
      _focusNodes[5].unfocus();
      _handleVerify();
    } else {
      _focusNodes[toFill.length.clamp(0, 5)].requestFocus();
    }
  }

  Widget _buildOtpBox(int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(), // Dummy node for listener, not used for focus
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.headlineMedium.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            // Paste support: if multiple digits pasted into one box, distribute
            if (value.length > 1) {
              _handlePaste(value);
              return;
            }
            if (value.isNotEmpty) {
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else {
                _focusNodes[index].unfocus();
                _handleVerify();
              }
            }
            setState(() {});
          },
          onTap: () =>
              _controllers[index].selection = TextSelection.fromPosition(
                TextPosition(offset: _controllers[index].text.length),
              ),
        ),
      ),
    );
  }
}
