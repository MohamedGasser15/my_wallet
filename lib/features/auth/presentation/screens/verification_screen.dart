import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:my_wallet/features/onboarding/presentation/screens/onboarding_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isLogin;
  final String? deviceName; 
  final String? ipAddress;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.isLogin,
    this.deviceName,
    this.ipAddress,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with TickerProviderStateMixin {
  // حقل مخفي واحد للتحكم في الإدخال
  late final TextEditingController _hiddenController;
  late final FocusNode _hiddenFocusNode;

  final AuthRepository _authRepository = AuthRepository();

  int _countdown = 60;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeSlideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // الكود الحالي
  String _code = '';

  @override
  void initState() {
    super.initState();
    _hiddenController = TextEditingController();
    _hiddenFocusNode = FocusNode();
    _startTimer();
    _initAnimations();

    // طلب التركيز على الحقل المخفي بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hiddenFocusNode.requestFocus();
    });
  }

  void _initAnimations() {
    _fadeSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeSlideController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeSlideController,
      curve: Curves.easeOut,
    ));
    _fadeSlideController.forward();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
        }
      });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _countdown = 60;
    });
    _startTimer();
  }

  void _onBackPressed() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen(onLocaleChanged: (locale) {})),
      (route) => false,
    );
  }

  // معالجة تغيير النص في الحقل المخفي
  void _onHiddenTextChanged(String value) {
    // السماح فقط بالأرقام
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits != value) {
      _hiddenController.text = digits;
      _hiddenController.selection = TextSelection.fromPosition(TextPosition(offset: digits.length));
    }

    setState(() {
      _code = digits;
    });

    // مسح رسالة الخطأ عند أي تغيير
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    // التحقق التلقائي عند اكتمال 6 أرقام
    if (digits.length == 6) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;

    // إخفاء الكيبورد بعد اكتمال الإدخال فقط
    _hiddenFocusNode.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authRepository.verifyCode(
        email: widget.email,
        verificationCode: _code,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/passcode',
            arguments: {
              'email': widget.email,
              'verificationCode': _code,
              'isLogin': widget.isLogin,
            },
          );
        }
      } else {
        setState(() {
          _errorMessage = context.l10n.invalidVerificationCode;
        });
        _showErrorShake();
        _clearCode();
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.l10n.verifyCodeFailed;
      });
      _showErrorShake();
      _clearCode();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearCode() {
    setState(() {
      _code = '';
    });
    _hiddenController.clear();
    // إعادة التركيز للحقل المخفي بعد الخطأ
    _hiddenFocusNode.requestFocus();
  }

  void _showErrorShake() {
    _shakeController.forward(from: 0.0);
  }

  Future<void> _resendCode() async {
    if (_countdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
    await _authRepository.resendCode(
  email: widget.email,
  isLogin: widget.isLogin,
  deviceName: widget.deviceName,   // أضف ده
  ipAddress: widget.ipAddress,     // أضف ده
);
      _resetTimer();
      _clearCode();
      _showSuccessSnackBar('Verification code resent to ${widget.email}');
    } catch (e) {
      _showErrorSnackBar('Failed to resend code. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[300]),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.red[300]),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _hiddenController.dispose();
    _hiddenFocusNode.dispose();
    _timer?.cancel();
    _fadeSlideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // حساب عرض المربعات مثل الأصل
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 40.0; // 20 + 20
    final spacing = 12.0;
    final totalSpacing = (6 - 1) * spacing;
    double fieldWidth = (screenWidth - horizontalPadding - totalSpacing) / 6;
    fieldWidth = fieldWidth.clamp(40.0, 56.0);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios, size: 20),
          onPressed: _onBackPressed,
        ),
        title: null,
      ),
      body: GestureDetector(
        // النقر على الخلفية يخفي الكيبورد
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with email chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.email,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      widget.isLogin ? context.l10n.enterVerificationCode : context.l10n.verifyYourEmail,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      widget.isLogin
                          ? 'Enter the 6-digit code sent to your email'
                          : 'Enter the verification code we sent to your email',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                    // الحقل المخفي (غير مرئي) لكنه موجود لربط الكيبورد
                    Opacity(
                      opacity: 0,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _hiddenController,
                          focusNode: _hiddenFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: _onHiddenTextChanged,
                          textInputAction: TextInputAction.done,
                          enableInteractiveSelection: true,
                          autofillHints: const [AutofillHints.oneTimeCode],
                        ),
                      ),
                    ),

                    // مربعات عرض OTP مع animate الاهتزاز
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: AutofillGroup(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) => _buildDisplayBox(index, fieldWidth, theme)),
                        ),
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: theme.colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Timer and resend
                    Center(
                      child: Column(
                        children: [
                          if (_countdown > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resend code in ${_formatCountdown(_countdown)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_countdown == 0)
                            TextButton(
                              onPressed: _isLoading ? null : _resendCode,
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!_isLoading) Icon(Icons.refresh, size: 18),
                                  if (!_isLoading) const SizedBox(width: 8),
                                  Text(
                                    _isLoading ? 'Resending...' : 'Resend code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_isLoading)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.primary,
                                        ),
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
          ),
        ),
      ),
    );
  }

  // دالة بناء كل مربع عرض بنفس تصميم الأصل
  Widget _buildDisplayBox(int index, double width, ThemeData theme) {
    final String digit = _code.length > index ? _code[index] : '';
    final bool isFilled = digit.isNotEmpty;
    final bool hasError = _errorMessage != null;

    return GestureDetector(
      onTap: () {
        // عند النقر على المربع، نعيد التركيز للحقل المخفي
        _hiddenFocusNode.requestFocus();
      },
      child: Container(
        width: width,
        height: 80,
        margin: EdgeInsets.only(left: index > 0 ? 12 : 0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasError
                ? theme.colorScheme.error
                : (isFilled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3)),
            width: hasError ? 2 : (isFilled ? 2 : 1.5),
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isFilled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}