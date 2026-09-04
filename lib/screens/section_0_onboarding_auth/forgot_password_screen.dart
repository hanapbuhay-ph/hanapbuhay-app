import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

enum ForgotPasswordStep { requestCode, verifyCode, resetPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.requestCode;
  
  final _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Timer for OTP
  Timer? _timer;
  int _secondsRemaining = 59;
  bool _canResend = false;

  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: 0), weight: 1),
    ]).animate(_shakeController!);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    _shakeController?.dispose();
    super.dispose();
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

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _handleRequestCode() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.forgotPassword(identifier);
      if (result.success) {
        setState(() => _currentStep = ForgotPasswordStep.verifyCode);
        _startTimer();
      } else {
        setState(() => _errorMessage = result.message);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otp.length < 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.verifyForgotPasswordOtp(_identifierController.text.trim(), _otp);
      if (result.success) {
        setState(() => _currentStep = ForgotPasswordStep.resetPassword);
      } else {
        _handleOtpError(result.message);
      }
    } catch (e) {
      _handleOtpError('Network error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleOtpError(String message) {
    setState(() => _errorMessage = message);
    _shakeController?.forward(from: 0);
    HapticFeedback.vibrate();
    for (var c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  Future<void> _handleResetPassword() async {
    final pass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass.length < 8) {
      setState(() => _errorMessage = 'Minimum 8 characters required');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.resetPassword(_identifierController.text.trim(), pass);
      if (result.success) {
        setState(() => _currentStep = ForgotPasswordStep.success);
      } else {
        setState(() => _errorMessage = result.message);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
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
              physics: const BouncingScrollPhysics(),
              child: _buildCurrentStep(),
            ),
          ),
          if (_currentStep != ForgotPasswordStep.success) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case ForgotPasswordStep.requestCode:
        return _buildRequestCodeView();
      case ForgotPasswordStep.verifyCode:
        return _buildVerifyCodeView();
      case ForgotPasswordStep.resetPassword:
        return _buildResetPasswordView();
      case ForgotPasswordStep.success:
        return _buildSuccessView();
    }
  }

  Widget _buildRequestCodeView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: colorScheme.surface, 
            shape: BoxShape.circle, 
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08), 
                blurRadius: 10, 
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 24),
        Text('Forgot Password?', style: AppTypography.headlineLarge.copyWith(fontSize: 28, color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Enter your email address and we\'ll send you a code to reset your password.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _identifierController,
          label: 'Email',
          hint: 'e.g., name@email.com',
          errorText: _errorMessage,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildVerifyCodeView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.mark_email_unread_outlined, size: 48, color: colorScheme.primary),
        ),
        const SizedBox(height: 32),
        Text('Verify your email', style: AppTypography.headlineLarge.copyWith(fontSize: 28, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            children: [
              const TextSpan(text: 'We sent a verification code to your email address\n'),
              TextSpan(
                text: _identifierController.text,
                style: AppTypography.labelLarge.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        if (_shakeAnimation != null)
          AnimatedBuilder(
            animation: _shakeAnimation!,
            builder: (context, child) => Transform.translate(offset: Offset(_shakeAnimation!.value, 0), child: child),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (index) => _buildOtpBox(index))),
          )
        else
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (index) => _buildOtpBox(index))),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: colorScheme.error)),
        ],
        const SizedBox(height: 40),
        Text(
          _canResend ? "Didn't receive the code?" : "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
          style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _canResend ? _handleRequestCode : null,
          child: Text(
            'Resend Code',
            style: AppTypography.labelLarge.copyWith(color: _canResend ? colorScheme.primary : colorScheme.outlineVariant, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 32),
        Text('HanapBuhay', style: AppTypography.headlineMedium.copyWith(color: colorScheme.primary, fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Text('Create New Password', style: AppTypography.headlineLarge.copyWith(fontSize: 28, color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Your new password must be different from previous used passwords.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Must be at least 8 characters',
          obscureText: _obscureNewPassword,
          suffixIcon: IconButton(
            icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off, size: 20, color: colorScheme.onSurfaceVariant),
            onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          errorText: _errorMessage,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          hint: 'Must match new password',
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, size: 20, color: colorScheme.onSurfaceVariant),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSuccessView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.check_circle, size: 48, color: colorScheme.primary),
          ),
          const SizedBox(height: 32),
          Text('Password Reset Successful', textAlign: TextAlign.center, style: AppTypography.headlineLarge.copyWith(fontSize: 28, color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          Text(
            'You can now log in with your new password. Keep it safe!',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          PrimaryButton(
            label: 'Back to Login',
            onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final colorScheme = Theme.of(context).colorScheme;
    String label = 'Send Reset Code';
    VoidCallback? onPressed = _handleRequestCode;

    if (_currentStep == ForgotPasswordStep.verifyCode) {
      label = 'Verify';
      onPressed = _otp.length == 6 ? _handleVerifyOtp : null;
    } else if (_currentStep == ForgotPasswordStep.resetPassword) {
      label = 'Reset Password';
      onPressed = _handleResetPassword;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: PrimaryButton(
        label: label,
        isLoading: _isLoading,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, String? hint, bool obscureText = false, Widget? suffixIcon, String? errorText}) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        labelStyle: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: AppTypography.labelSmall.copyWith(color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 44, height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _otpFocusNodes[index].hasFocus ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5), width: _otpFocusNodes[index].hasFocus ? 2 : 1),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _otpControllers[index].text.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.headlineMedium.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800),
          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else {
                _otpFocusNodes[index].unfocus();
                _handleVerifyOtp();
              }
            }
            setState(() {});
          },
        ),
      ),
    );
  }
}
