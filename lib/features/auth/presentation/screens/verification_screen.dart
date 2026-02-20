import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _VerificationScreenState extends State<VerificationScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthRepository _authRepository = AuthRepository();
  
  int _countdown = 60;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Animation controllers
  late AnimationController _fadeSlideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Shake animation controller
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initAnimations();
    _checkClipboardForCode();
    _setupBackspaceHandlers();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
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

    // Shake animation
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
  
  void _setupBackspaceHandlers() {
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            // Move focus to previous and clear it
            _focusNodes[i - 1].requestFocus();
            _controllers[i - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }
  
  Future<void> _checkClipboardForCode() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      final text = clipboardData?.text;
      if (text != null && text.length == 6 && RegExp(r'^\d{6}$').hasMatch(text)) {
        _showPasteSuggestion(text);
      }
    } catch (e) {
      print('Error checking clipboard: $e');
    }
  }
  
  void _showPasteSuggestion(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.content_paste, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Detected a 6-digit code in clipboard. Paste it?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                _pasteCode(code);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text('Paste', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey[800],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _pasteCode(String code) {
    // Extract only digits
    String digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 6) digits = digits.substring(0, 6);
    
    for (int i = 0; i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
    // Fill remaining with empty if less than 6
    for (int i = digits.length; i < 6; i++) {
      _controllers[i].clear();
    }
    
    // Move focus to last filled or first empty
    if (digits.length == 6) {
      FocusScope.of(context).unfocus();
      _verifyCode(); // Auto verify after full paste
    } else {
      FocusScope.of(context).requestFocus(_focusNodes[digits.length]);
    }
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
    // If pasted multiple characters
    if (value.length > 1) {
      _pasteCode(value);
      return;
    }
    
    // Validate single digit
    if (value.isNotEmpty && !RegExp(r'^\d$').hasMatch(value)) {
      _controllers[index].clear();
      return;
    }
    
    // Handle single character input
    if (value.length == 1) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    }
    
    // Clear error message on any change
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    
    // Auto verify when all fields filled
    if (_controllers.every((c) => c.text.length == 1)) {
      _verifyCode();
    }
  }
  
  Future<void> _verifyCode() async {
    // Prevent multiple verifications
    if (_isLoading) return;
    
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    String code = _controllers.map((c) => c.text).join();
    
    try {
      final result = await _authRepository.verifyCode(
        email: widget.email,
        verificationCode: code,
      );
      
      if (result['success'] == true) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/passcode',
            arguments: {
              'email': widget.email,
              'verificationCode': code,
              'isLogin': widget.isLogin,
            },
          );
        }
      } else {
        setState(() {
          _errorMessage = context.l10n.invalidVerificationCode;
        });
        _showErrorShake();
        _clearFieldsOnError();
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.l10n.verifyCodeFailed;
      });
      _showErrorShake();
      _clearFieldsOnError();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _clearFieldsOnError() {
    for (var c in _controllers) {
      c.clear();
    }
    FocusScope.of(context).requestFocus(_focusNodes[0]);
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
      await _authRepository.resendCode(widget.email, widget.isLogin);
      
      _resetTimer();
      for (var c in _controllers) c.clear();
      FocusScope.of(context).requestFocus(_focusNodes[0]);
      
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
    for (var c in _controllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    _timer?.cancel();
    _fadeSlideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final isRTL = Directionality.of(context) == TextDirection.rtl;

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
    body: SafeArea(
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

                const SizedBox(height: 40),

                // Responsive OTP fields with shake animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate field width dynamically to avoid overflow
                      const double spacing = 12; // desired space between fields
                      final double availableWidth = constraints.maxWidth;
                      final double totalSpacing = (6 - 1) * spacing;
                      double fieldWidth = (availableWidth - totalSpacing) / 6;
                      // Clamp between a minimum (40) and maximum (56) for usability
                      fieldWidth = fieldWidth.clamp(40.0, 56.0);

                      return AutofillGroup(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            6,
                            (index) => _buildCodeField(
                              index,
                              theme,
                              fieldWidth: fieldWidth,
                              spacing: spacing,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Error message (same as before)
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

                // Timer and resend (same as before)
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

                const SizedBox(height: 20),

                // Hint about paste (same as before)
                if (_countdown > 0)
                  Center(
                    child: Text(
                      'Paste the code from your email',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Updated field builder with dynamic width and spacing
Widget _buildCodeField(int index, ThemeData theme, {required double fieldWidth, required double spacing}) {
  final isFilled = _controllers[index].text.isNotEmpty;
  final hasError = _errorMessage != null;

  return Container(
    width: fieldWidth,
    height: 80, // keep height fixed
    margin: EdgeInsets.only(
      left: index > 0 ? spacing : 0,
    ),
    child: TextField(
      controller: _controllers[index],
      focusNode: _focusNodes[index],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 1,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: hasError
                ? theme.colorScheme.error
                : (isFilled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3)),
            width: hasError ? 2 : (isFilled ? 2 : 1.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: hasError
                ? theme.colorScheme.error
                : theme.colorScheme.outline.withOpacity(0.3),
            width: hasError ? 2 : (isFilled ? 2 : 1.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      enableInteractiveSelection: true,
      autofillHints: const [AutofillHints.oneTimeCode],
      contextMenuBuilder: (context, editableTextState) {
        final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
      onChanged: (value) => _onCodeChanged(index, value),
      textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
    ),
  );
}
}