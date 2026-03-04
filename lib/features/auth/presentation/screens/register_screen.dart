import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:my_wallet/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:my_wallet/core/services/message_service.dart'; // إضافة
import 'package:my_wallet/core/enums/message_type.dart'; // إضافة

class RegisterScreen extends StatefulWidget {
  final String email;
  final String verificationCode;
  final String passcode;
  
  const RegisterScreen({
    super.key,
    required this.email,
    required this.verificationCode,
    required this.passcode,
  });
  
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isLoading = false;
  
  void _onBackPressed() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen(onLocaleChanged: (locale) {})),
      (route) => false,
    );
  }
  
  Future<void> _onComplete() async {
    // التحقق من ملء جميع الحقول
    if (_fullNameController.text.isEmpty ||
        _userNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty) {
      MessageService.showError('Please fill all fields');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _authRepository.completeRegistration(
        email: widget.email,
        verificationCode: widget.verificationCode,
        password: widget.passcode,
        fullName: _fullNameController.text,
        userName: _userNameController.text,
        phoneNumber: _phoneNumberController.text,
      );
      
      if (result['success'] == true) {
        // عرض رسالة نجاح ثم الانتقال للصفحة الرئيسية
        MessageService.showSuccess('Registration completed successfully!');
        // تأخير بسيط للسماح برؤية الرسالة
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      } else {
        MessageService.showError(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      MessageService.showError('Failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    _phoneNumberController.dispose();
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
              context.l10n.completeRegistration,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              context.l10n.enterYourDetails,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // تم إزالة قسم عرض _errorMessage
            
            // Full Name
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: context.l10n.fullName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Username
            TextField(
              controller: _userNameController,
              decoration: InputDecoration(
                labelText: context.l10n.userName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Phone Number
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.l10n.phoneNumber,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onComplete,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(context.l10n.complete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}