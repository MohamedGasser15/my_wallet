import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:my_wallet/features/onboarding/presentation/screens/onboarding_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});
  
  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isEmailValid = false;
  bool _isLoading = false;
  bool _emailExists = false;
  
  // Wave loading animation variables
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  final List<double> _dotScales = [1.0, 1.0, 1.0];
  final List<double> _dotOpacities = [0.5, 0.5, 0.5];
  
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    
    // Initialize wave animation controller
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  void _startWaveAnimation() {
    _waveController.repeat(reverse: true);
    
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !_isLoading) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Create wave effect for 3 dots
        final time = DateTime.now().millisecondsSinceEpoch / 500;
        
        for (int i = 0; i < 3; i++) {
          double phase = i * 0.8;
          double waveValue = sin(time - phase);
          
          // Normalize to [0.5, 1.0] range for opacity
          _dotOpacities[i] = 0.5 + ((waveValue + 1) / 2) * 0.5;
          
          // Normalize to [0.8, 1.2] range for scale
          _dotScales[i] = 0.8 + ((waveValue + 1) / 2) * 0.4;
        }
      });
    });
  }
  
  void _stopWaveAnimation() {
    _waveController.stop();
    setState(() {
      // Reset dots to normal state
      for (int i = 0; i < 3; i++) {
        _dotScales[i] = 1.0;
        _dotOpacities[i] = 0.5;
      }
    });
  }
  
  void _validateEmail() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    setState(() {
      _isEmailValid = emailRegex.hasMatch(email);
    });
  }
  
  Future<void> _checkEmail() async {
    if (!_isEmailValid) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Start wave animation
    _startWaveAnimation();
    
    try {
      final email = _emailController.text.trim();
      final exists = await _authRepository.checkEmail(email);
      
      setState(() {
        _emailExists = exists;
      });
      
      // إرسال كود التحقق
      await _sendVerificationCode();
      
      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _stopWaveAnimation();
    }
  }
  
  Future<void> _sendVerificationCode() async {
    try {
      final email = _emailController.text.trim();
      final isLogin = _emailExists;
      
      await _authRepository.sendVerification(email, isLogin);
      
      // الانتقال لشاشة التحقق
      Navigator.pushNamed(
        context,
        '/verification',
        arguments: {
          'email': email,
          'isLogin': isLogin,
        },
      );
    } catch (e) {
      _showErrorSnackbar('Failed to send verification code');
    }
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
  
  void _onBackPressed() {
    // الرجوع لشاشة Onboarding
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen(onLocaleChanged: (locale) {})),
      (route) => false,
    );
  }
  
  void _onLostAccess() {
    // TODO: Handle lost access to email
    print('Lost access to email');
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _waveController.dispose();
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
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    context.l10n.whatIsYourEmail,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    context.l10n.enterYourEmailDescription,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Email Input Field
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: context.l10n.email,
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                      ),
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
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                      suffixIcon: _emailController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                              ),
                              onPressed: () {
                                _emailController.clear();
                                setState(() {
                                  _isEmailValid = false;
                                  _emailExists = false;
                                });
                              },
                            )
                          : null,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onSubmitted: (_) {
                      if (_isEmailValid) _checkEmail();
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Lost Access Link باللون الأزرق
                  Center(
                    child: GestureDetector(
                      onTap: _onLostAccess,
                      child: Text(
                        context.l10n.lostAccessToEmail,
                        style: TextStyle(
                          color: Colors.blue, // اللون الأزرق المطلوب
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  // Spacer
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          // Continue Button with Wave Loading
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEmailValid && !_isLoading ? _checkEmail : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                disabledForegroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 60,
                      height: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 8 * _dotScales[index],
                            height: 8 * _dotScales[index],
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary
                                  .withOpacity(_dotOpacities[index]),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    )
                  : Text(
                      context.l10n.continueText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}