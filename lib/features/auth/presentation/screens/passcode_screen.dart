import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
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

class _PasscodeScreenState extends State<PasscodeScreen> with TickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();
  final List<String> _passcode = [];
  final int _passcodeLength = 6;
  
  bool _isLoading = false;
  bool _showError = false;
  String? _errorMessage;
  Timer? _resetTimer;
  
  // Animation for dots
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }
  
  void _onBackPressed() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen(onLocaleChanged: (locale) {})),
      (route) => false,
    );
  }
  
  void _addDigit(String digit) {
    if (_passcode.length < _passcodeLength && !_isLoading && !_showError) {
      setState(() {
        _passcode.add(digit);
        _errorMessage = null;
      });
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      if (_passcode.length == _passcodeLength) {
        _completeProcess();
      }
    }
  }
  
  void _removeDigit() {
    if (_passcode.isNotEmpty && !_isLoading && !_showError) {
      setState(() {
        _passcode.removeLast();
        _errorMessage = null;
      });
      HapticFeedback.selectionClick();
    }
  }
  
  void _clearPasscode() {
    if (!_isLoading && !_showError) {
      setState(() {
        _passcode.clear();
        _errorMessage = null;
      });
    }
  }
  
  Future<void> _completeProcess() async {
    setState(() {
      _isLoading = true;
      _showError = false;
      _errorMessage = null;
    });
    
    String passcode = _passcode.join();
    
    try {
      if (widget.isLogin) {
        final result = await _authRepository.completeLogin(
          email: widget.email,
          verificationCode: widget.verificationCode,
          password: passcode,
        );
        
        if (result['success'] == true) {
          await SharedPrefs.setString('user_password', passcode);
          _navigateToHome();
        } else {
          _showErrorState('Invalid passcode');
        }
      } else {
        // Save passcode locally before navigating to register
        await SharedPrefs.setString('user_password', passcode);
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
      _showErrorState('An error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showErrorState(String message) {
    setState(() {
      _showError = true;
      _errorMessage = message;
    });
    
    // Shake animation
    _shakeController.forward(from: 0.0);
    
    // Clear after delay
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _passcode.clear();
          _showError = false;
          _errorMessage = null;
        });
      }
    });
  }
  
  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }
  
  void _onForgotPasscode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildForgotPasscodeSheet(),
    );
  }
  
  Widget _buildForgotPasscodeSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.lock_reset,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Reset Passcode',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A new verification code will be sent to your email.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    
                    try {
                      await _authRepository.sendVerification(widget.email, widget.isLogin);
                      _showSuccessSnackBar('New code sent to ${widget.email}');
                    } catch (e) {
                      _showErrorSnackBar('Failed to send code');
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  // بناء لوحة المفاتيح
  Widget _buildKeyboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // الصفوف 1-2-3
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 16),
          // الصف الأخير: نص (Forget) - 0 - زر حذف
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Forget (يظهر فقط في حالة login)
              widget.isLogin
                  ? _buildTextButton('Forget?', onTap: _onForgotPasscode)
                  : const SizedBox(width: 80),
              
              _buildNumberButton('0'),
              
              _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildNumberButton(digit)).toList(),
    );
  }
  
  Widget _buildNumberButton(String digit) {
    return _KeyboardButton(
      onTap: () => _addDigit(digit),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDeleteButton() {
    return _KeyboardButton(
      onTap: _removeDigit,
      onLongPress: _clearPasscode,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: _passcode.isNotEmpty && !_isLoading
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextButton(String text, {required VoidCallback onTap}) {
    return _KeyboardButton(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  // بناء النقاط
  Widget _buildPasscodeIndicators() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_showError ? _shakeAnimation.value : 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_passcodeLength, (index) {
              final isFilled = index < _passcode.length;
              final isError = _showError && isFilled;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isError
                      ? Colors.red
                      : isFilled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  border: !isFilled
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isFilled && !isError
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isLogin ? Icons.lock_outline : Icons.lock_reset,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      widget.isLogin ? context.l10n.enterYourPasscode : context.l10n.setPasscodeTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    if (!widget.isLogin)
                      Text(
                        context.l10n.setPasscodeDescription,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    
                    const SizedBox(height: 48),
                    
                    // Passcode indicators
                    _buildPasscodeIndicators(),
                    
                    const SizedBox(height: 24),
                    
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            
            // Custom Keyboard
            _buildKeyboard(),
          ],
        ),
      ),
    );
  }
}

// زر مخصص مع تأثير اللمس
class _KeyboardButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  
  const _KeyboardButton({
    required this.onTap,
    this.onLongPress,
    required this.child,
  });
  
  @override
  State<_KeyboardButton> createState() => __KeyboardButtonState();
}

class __KeyboardButtonState extends State<_KeyboardButton> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.9 : 1.0,
        child: widget.child,
      ),
    );
  }
}