// features/auth/presentation/screens/pin_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_wallet/core/services/biometric_service.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/auth/presentation/widgets/biometric_bottom_sheet.dart';
import 'package:my_wallet/features/home/presentation/screens/HomeScreen.dart';

class PinScreen extends StatefulWidget {
  final bool isFirstTime;
  final bool showBiometricFirst;
  
  const PinScreen({
    super.key, 
    this.isFirstTime = false,
    this.showBiometricFirst = true,
  });
  
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _pinDigits = [];
  bool _isLoading = false;
  bool _showError = false;
  String? _errorMessage;
  Timer? _errorTimer;
  bool _biometricFailed = false;
  String _biometricName = 'Face ID';
  bool _biometricEnabled = false;
  bool _hasBiometricSupport = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricData();
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBiometricData() async {
    final name = await BiometricService.getBiometricName();
    final isEnabled = await BiometricService.isBiometricEnabled();
    final hasSupport = await BiometricService.hasBiometricSupport();
    
    setState(() {
      _biometricName = name;
      _biometricEnabled = isEnabled;
      _hasBiometricSupport = hasSupport;
    });

    // إذا كان البايومتريك مفعل وعنده دعم، جرب المصادقة مباشرة
    if (_biometricEnabled && 
        _hasBiometricSupport && 
        !widget.isFirstTime &&
        widget.showBiometricFirst &&
        !_biometricFailed) {
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authenticated = await BiometricService.authenticate();
      
      if (authenticated) {
        _navigateToHome();
        return;
      } else {
        // إذا فشلت مصادقة البايومتريك، نعلم المستخدم وننتظر الـ PIN
        setState(() {
          _biometricFailed = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_biometricName authentication failed. Please use PIN'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _navigateToHome() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _addDigit(String digit) {
    if (_pinDigits.length < 6 && !_isLoading) {
      setState(() {
        _pinDigits.add(digit);
        _showError = false;
        _errorMessage = null;
        _biometricFailed = false; // Reset biometric failed state
      });

      if (_pinDigits.length == 6) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (_pinDigits.isNotEmpty && !_isLoading) {
      setState(() {
        _pinDigits.removeLast();
        _showError = false;
        _errorMessage = null;
      });
    }
  }

  void _clearPin() {
    if (!_isLoading) {
      setState(() {
        _pinDigits.clear();
        _showError = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    // محاكاة التحقق من PIN
    await Future.delayed(const Duration(milliseconds: 500));

    // في التطبيق الحقيقي، هنا نتحقق من السيرفر
    final storedPassword = await SharedPrefs.getStringValue('user_password');
    final enteredPin = _pinDigits.join();

    if (storedPassword == enteredPin) {
      // PIN صحيح
      setState(() {
        _isLoading = false;
      });

      // التحقق من إمكانية استخدام البايومتريك
      if (_hasBiometricSupport && !_biometricEnabled && !widget.isFirstTime) {
        // عرض الـ Bottom Sheet لتفعيل البايومتريك
        _showBiometricBottomSheet();
      } else {
        _navigateToHome();
      }
    } else {
      // PIN خطأ
      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = 'Incorrect PIN';
      });

      _errorTimer?.cancel();
      _errorTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _pinDigits.clear();
            _showError = false;
            _errorMessage = null;
          });
        }
      });
    }
  }

  void _showBiometricBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BiometricBottomSheet(biometricName: _biometricName),
    ).then((value) {
      if (value == true) {
        _navigateToHome();
      }
    });
  }

  Future<void> _tryBiometricAgain() async {
    setState(() {
      _isLoading = true;
    });
    
    final authenticated = await BiometricService.authenticate();
    
    setState(() {
      _isLoading = false;
    });
    
    if (authenticated) {
      _navigateToHome();
    } else {
      setState(() {
        _biometricFailed = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_biometricName authentication failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onForgotPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text('You will need to reset your PIN through email verification.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to reset PIN flow
            },
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return Container(
      margin: const EdgeInsets.only(bottom: 40, top: 20),
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final isFilled = index < _pinDigits.length;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _showError 
                  ? Colors.red
                  : (isFilled 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
              border: !isFilled ? Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                width: 1.0,
              ) : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          // الصف الأول: 1 2 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          const SizedBox(height: 24),
          
          // الصف الثاني: 4 5 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          const SizedBox(height: 24),
          
          // الصف الثالث: 7 8 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          const SizedBox(height: 24),
          
          // الصف الرابع: Forget - 0 - Delete/Biometric
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Forget على اليسار
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _onForgotPin,
                  child: Text(
                    'Forget?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              // الرقم 0 في المنتصف
              _buildNumberButton('0'),
              
              // زر الحذف أو البايومتريك على اليمين
              // إذا كان PIN فارغ ولم يفشل البايومتريك وكان البايومتريك مفعل، نعرض زر البايومتريك
              // إذا كان فيه أرقام أو البايومتريك غير مفعل، نعرض زر الحذف
              _pinDigits.isEmpty && !_biometricFailed && _biometricEnabled
                  ? _buildBiometricButton()
                  : _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String digit) {
    return GestureDetector(
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

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _removeDigit,
      onLongPress: _clearPin,
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
            color: _pinDigits.isNotEmpty && !_isLoading
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    // اختيار الأيقونة المناسبة بناءً على نوع البايومتريك
    IconData iconData;
    if (_biometricName.toLowerCase().contains('face')) {
      iconData = Icons.face; // أيقونة Face ID
    } else if (_biometricName.toLowerCase().contains('finger')) {
      iconData = Icons.fingerprint; // أيقونة Fingerprint
    } else {
      iconData = Icons.security; // أيقونة افتراضية
    }

    return GestureDetector(
      onTap: _tryBiometricAgain,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(
            iconData,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // المحتوى الرئيسي - بدون AppBar
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Enter PIN',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'Enter your 6-digit PIN to access your wallet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // PIN Dots
                  _buildPinDots(),
                  
                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  // Loading Indicator
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            
            // لوحة المفاتيح الرقمية
            _buildNumericKeypad(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}