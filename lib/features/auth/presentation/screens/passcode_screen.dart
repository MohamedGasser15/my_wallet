// features/auth/presentation/screens/passcode_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

class _PasscodeScreenState extends State<PasscodeScreen> with SingleTickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();
  final List<String> _passcode = [];
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showError = false;
  Timer? _waveTimer;
  Timer? _errorTimer;
  Timer? _resetTimer;
  
  // Wave animation variables
  final List<double> _dotHeights = List.generate(6, (index) => 0.0);
  final List<Color> _dotColors = List.generate(6, (index) => Colors.transparent);
  final List<double> _dotScales = List.generate(6, (index) => 1.0);
  double _wavePosition = 0.0;
  bool _isWaving = false;
  
  // Vibration animation
  late AnimationController _vibrateController;
  late Animation<double> _vibrateAnimation;
  bool _isVibrating = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize vibration animation
    _vibrateController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _vibrateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_vibrateController);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }
  
  @override
  void dispose() {
    _waveTimer?.cancel();
    _errorTimer?.cancel();
    _resetTimer?.cancel();
    _vibrateController.dispose();
    super.dispose();
  }
  
  void _startWaveAnimation() {
    _waveTimer?.cancel();
    _isWaving = true;
    
    _waveTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) return;
      
      setState(() {
        _wavePosition += 0.15;
        
        // Create smooth horizontal wave effect
        for (int i = 0; i < 6; i++) {
          // Each dot has a phase offset for wave effect
          double phaseOffset = i * 0.8; // Adjust for wave steepness
          double waveValue = sin(_wavePosition - phaseOffset);
          
          // Normalize wave value to [0, 1] range
          double normalizedValue = (waveValue + 1) / 2;
          
          // Set dot height (vertical movement)
          _dotHeights[i] = normalizedValue * 18; // Max 18px movement
          
          // Set dot scale (size change)
          _dotScales[i] = 1.0 + (normalizedValue * 0.25); // Scale from 1.0 to 1.25
        }
      });
    });
  }
  
  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    _isWaving = false;
    
    // Smoothly reset dots to normal position
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) {
          setState(() {
            _dotHeights[i] = 0.0;
            _dotScales[i] = 1.0;
          });
        }
      });
    }
    
    setState(() {
      _wavePosition = 0.0;
    });
  }
  
  void _triggerVibration() async {
    if (_isVibrating) return;
    
    _isVibrating = true;
    
    // Start vibration animation
    for (int i = 0; i < 5; i++) { // Vibrate 5 times
      await _vibrateController.forward();
      await _vibrateController.reverse();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    _isVibrating = false;
  }
  
  void _showErrorState() {
    // Change dots to red
    setState(() {
      for (int i = 0; i < _passcode.length; i++) {
        _dotColors[i] = Colors.red;
      }
      _showError = true;
    });
    
    // Trigger vibration
    _triggerVibration();
    
    // Stop wave animation
    _stopWaveAnimation();
    
    // Reset after 2 seconds
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // Smoothly reset dots to normal
      for (int i = 0; i < 6; i++) {
        Future.delayed(Duration(milliseconds: i * 40), () {
          if (mounted) {
            setState(() {
              _dotColors[i] = Colors.transparent;
              _dotHeights[i] = 0.0;
              _dotScales[i] = 1.0;
            });
          }
        });
      }
      
      setState(() {
        _passcode.clear();
        _showError = false;
        _isLoading = false;
        _isSubmitting = false;
      });
    });
  }
  
  void _showSuccessState() {
    // Keep wave animation for 2 seconds
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // Navigate after 2 seconds
      Navigator.pushReplacementNamed(context, '/home');
    });
  }
  
  void _onBackPressed() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen(onLocaleChanged: (locale) {})),
      (route) => false,
    );
  }
  
  void _addDigit(String digit) {
    if (_passcode.length < 6 && !_isLoading && !_showError) {
      setState(() {
        _passcode.add(digit);
      });
      
      if (_passcode.length == 6) {
        _completeProcess();
      }
    }
  }
  
  void _removeDigit() {
    if (_passcode.isNotEmpty && !_isLoading && !_showError) {
      setState(() {
        _passcode.removeLast();
      });
    }
  }
  
  void _clearPasscode() {
    if (!_isLoading && !_showError) {
      setState(() {
        _passcode.clear();
      });
    }
  }
  
  Future<void> _completeProcess() async {
  setState(() {
    _isLoading = true;
    _isSubmitting = true;
  });

  // Start wave animation
  _startWaveAnimation();

  String passcode = _passcode.join();

  try {
    if (widget.isLogin) {
      final result = await _authRepository.completeLogin(
        email: widget.email,
        verificationCode: widget.verificationCode,
        password: passcode,
      );

      if (result['success'] == true) {
        // Save passcode locally
        await SharedPrefs.setString('user_password', passcode);

        // Show success state for 2 seconds
        _showSuccessState();
      } else {
        _showErrorState();
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
    _showErrorState();
  } finally {
    setState(() {
      _isLoading = false;
      _isSubmitting = false;
    });
  }
}
  
  void _onForgotPasscode() {
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
  
  // لوحة المفاتيح المخصصة
  Widget _buildCustomKeyboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          // الصف الأول: 1 2 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 24),
          
          // الصف الثاني: 4 5 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 24),
          
          // الصف الثالث: 7 8 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 24),
          
          // الصف الرابع: Forget - 0 - Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Forget على اليسار
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: widget.isLogin
                    ? GestureDetector(
                        onTap: _onForgotPasscode,
                        child: Text(
                          context.l10n.forgotPasscode,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              
              // الرقم 0 في المنتصف
              _buildKey('0'),
              
              // زر الحذف على اليمين
              _buildDeleteKey(),
            ],
          ),
        ],
      ),
    );
  }
  
  // زر الرقم
  Widget _buildKey(String digit) {
    return AnimatedButton(
      onTap: () => _addDigit(digit),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
  
  // زر الحذف
  Widget _buildDeleteKey() {
    return AnimatedButton(
      onTap: _removeDigit,
      onLongPress: _clearPasscode,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: _passcode.isNotEmpty && !_isLoading && !_showError
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
  
  // عرض نقاط الباسكود مع Wave Loading Animation
  Widget _buildPasscodeDots() {
    return AnimatedBuilder(
      animation: _vibrateAnimation,
      builder: (context, child) {
        double vibrateOffset = _isVibrating ? _vibrateAnimation.value : 0.0;
        
        return Transform.translate(
          offset: Offset(vibrateOffset, 0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 60, top: 20),
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _passcode.length;
                final dotColor = _dotColors[index];
                final verticalOffset = _dotHeights[index];
                final dotScale = _dotScales[index];
                
                // Calculate dot size with wave effect
                double baseSize = 16;
                double animatedSize = baseSize * dotScale;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: animatedSize,
                  height: animatedSize,
                  transform: Matrix4.translationValues(0, -verticalOffset, 0)
                    ..scale(dotScale),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor != Colors.transparent 
                        ? dotColor 
                        : (isFilled 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
                    border: !isFilled ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      width: 1.0,
                    ) : null,
                    boxShadow: isFilled && _isWaving && verticalOffset > 8
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                    
                    // Wave Loading Dots
                    _buildPasscodeDots(),
                  ],
                ),
              ),
            ),
            
            // Custom Keyboard
            _buildCustomKeyboard(),
            
            // مسافة من الأسفل
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Widget مخصص للزر مع animation
class AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  
  const AnimatedButton({
    super.key,
    required this.onTap,
    this.onLongPress,
    required this.child,
  });
  
  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.9 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}