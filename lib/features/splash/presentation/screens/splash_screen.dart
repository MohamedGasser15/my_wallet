import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:my_wallet/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  
  const SplashScreen({super.key, required this.onLocaleChanged});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _initAnimation();
    _checkAuthStatus();
  }
  
  void _initAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.forward();
  }
  
  Future<void> _checkAuthStatus() async {
    await SharedPrefs.init();

    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    final token = SharedPrefs.authToken;

    if (token == null || token.isEmpty) {
      // ❗ مفيش تسجيل → Onboarding
      _navigateToOnboarding();
    } else {
      // ✅ مسجل دخول
      _navigateToHome();
    }
  }
  
  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
  }
  
  void _navigateToHome() {
    // TODO: Navigate to home screen
    print('Navigate to home');
  }
  
  void _navigateToAuth() {
    // TODO: Navigate to auth screen
    print('Navigate to auth');
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_animation.value * 0.2),
              child: Opacity(
                opacity: _animation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // App Name
              Text(
                context.l10n.appTitle,

                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                context.l10n.manageYourMoneyEasily,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}