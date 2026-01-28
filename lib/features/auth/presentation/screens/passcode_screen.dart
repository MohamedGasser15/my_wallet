import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:my_wallet/features/onboarding/presentation/screens/onboarding_screen.dart';

class PasscodeScreen extends StatefulWidget {
  final String email;
  final String verificationCode;
  final bool isLogin;
  
  const PasscodeScreen({
    super.key,
    required this.email,
    required this.verificationCode,
    required this.isLogin,
  });
  
  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }
  
  void _onBackPressed() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen(onLocaleChanged: (locale) {})),
      (route) => false,
    );
  }
  
  void _onPasscodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
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
      _completeProcess();
    }
  }
  
  Future<void> _completeProcess() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    String passcode = '';
    for (var controller in _controllers) {
      passcode += controller.text;
    }
    
    try {
      if (widget.isLogin) {
        // عملية الدخول
        final result = await _authRepository.completeLogin(
          email: widget.email,
          verificationCode: widget.verificationCode,
          password: passcode,
        );
        
        if (result['success'] == true) {
          // الدخول ناجح، الانتقال للصفحة الرئيسية
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Login failed';
          });
        }
      } else {
        // عملية التسجيل، الانتقال لصفحة البيانات
        Navigator.pushNamed(
          context,
          '/register',
          arguments: {
            'email': widget.email,
            'verificationCode': widget.verificationCode,
            'passcode': passcode,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onForgotPasscode() {
    // إعادة إرسال كود التحقق
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Passcode'),
        content: const Text('A new verification code will be sent to your email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              
              try {
                await _authRepository.sendVerification(widget.email, widget.isLogin);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New code sent to ${widget.email}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send code: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
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
              widget.isLogin ? context.l10n.enterYourPasscode : context.l10n.setPasscodeTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle for register
            if (!widget.isLogin) ...[
              Text(
                context.l10n.setPasscodeDescription,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
            ] else
              const SizedBox(height: 40),
            
            // Passcode Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    obscureText: true,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                    onChanged: (value) => _onPasscodeChanged(index, value),
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
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Forgot Passcode (only for login)
            if (widget.isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onForgotPasscode,
                  child: Text(
                    context.l10n.forgotPasscode,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 40),
            
            // Loading Indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}