import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:my_wallet/features/onboarding/presentation/screens/onboarding_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isLogin;
  
  const VerificationScreen({
    super.key,
    required this.email,
    required this.isLogin,
  });
  
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthRepository _authRepository = AuthRepository();
  
  int _countdown = 60;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
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
  
  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    
    // إخفاء رسالة الخطأ عند البدء في الكتابة
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
    
    // Check if all fields are filled
    bool allFilled = true;
    for (var controller in _controllers) {
      if (controller.text.isEmpty) {
        allFilled = false;
        break;
      }
    }
    
    if (allFilled) {
      _verifyCode();
    }
  }
  
Future<void> _verifyCode() async {
  // إخفاء الكيبورد
  FocusScope.of(context).unfocus();
  
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  
  String code = '';
  for (var controller in _controllers) {
    code += controller.text;
  }
  
  try {
    final result = await _authRepository.verifyCode(
      email: widget.email,
      verificationCode: code,
    );
    
    if (result['success'] == true) {
      // التحقق ناجح، الانتقال لصفحة الباسكود
      Navigator.pushNamed(
        context,
        '/passcode',
        arguments: {
          'email': widget.email,
          'verificationCode': code,
          'isLogin': widget.isLogin,
        },
      );
    } else {
      // استخدم النص المترجم بدلاً من النص الثابت
      setState(() {
        _errorMessage = context.l10n.invalidVerificationCode;
      });
      // مسح الحقول عند الخطأ
      for (var controller in _controllers) {
        controller.clear();
      }
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }
  } catch (e) {
    // استخدم النص المترجم لرسالة الخطأ
    setState(() {
      _errorMessage = context.l10n.verifyCodeFailed;
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  Future<void> _resendCode() async {
    if (_countdown > 0) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _authRepository.resendCode(widget.email, widget.isLogin);

      // إعادة تشغيل العداد
      _resetTimer();

      // مسح الحقول
      for (var controller in _controllers) {
        controller.clear();
      }
      FocusScope.of(context).requestFocus(_focusNodes[0]);

    } catch (e) {
      // متجاهلين الخطأ من غير عرض أي رسالة
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

  }
  
  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
            size: 20,
          ),
          onPressed: _onBackPressed,
        ),
        title: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Title
            Text(
              widget.isLogin ? context.l10n.enterVerificationCode : context.l10n.verifyYourEmail,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              widget.isLogin 
                  ? '${context.l10n.enterCodeSentSms} ${widget.email}'
                  : '${context.l10n.enterCodeSentEmail} ${widget.email}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Code Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 60,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (value) => _onCodeChanged(index, value),
                    // إصلاح مشكلة الحروف العربية/الإنجليزية
                    textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
                  ),
                );
              }),
            ),
            
            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Timer and Resend Code
            Center(
              child: Column(
                children: [
                  // Countdown Timer
                  if (_countdown > 0)
                    Text(
                      '${context.l10n.resendCodeIn} ${_formatCountdown(_countdown)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  
                  // Resend Code Button (shown only when timer is 0)
                  if (_countdown == 0) ...[
                    GestureDetector(
                      onTap: _resendCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          context.l10n.resendCode,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Loading Indicator
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}