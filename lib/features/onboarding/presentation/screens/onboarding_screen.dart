// features/onboarding/presentation/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:my_wallet/features/onboarding/presentation/widgets/language_switch.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'مرحباً بك في محفظتي',
      description: 'تطبيقك الشخصي لإدارة المصروفات والمدخرات بكل سهولة ومرونة',
      icon: Icons.wallet,
      imagePath: 'assets/images/onboarding_1.svg',
    ),
    OnboardingPageData(
      title: 'تتبع كل حركة',
      description: 'سجل جميع مصروفاتك وإيراداتك في مكان واحد مع تفاصيل كاملة',
      icon: Icons.track_changes,
      imagePath: 'assets/images/onboarding_2.svg',
    ),
    OnboardingPageData(
      title: 'خطط لمستقبلك',
      description: 'اضبط ميزانيتك وتابع تقدمك نحو أهدافك المالية',
      icon: Icons.insights,
      imagePath: 'assets/images/onboarding_3.svg',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }
  
  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page?.round() ?? 0;
    });
  }
  
  Future<void> _onGetStarted() async {
    await SharedPrefs.setFirstTime(false);
    
    // TODO: Navigate to email screen
    print('Navigate to email screen');
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageSwitch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Page View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingPageWidget(
                  data: _pages[index],
                );
              },
            ),
          ),
          
          // Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: Theme.of(context).colorScheme.primary,
                dotColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
                expansionFactor: 3,
              ),
            ),
          ),
          
          // Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ابدأ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                     color: Colors.white, // null عشان ياخد لون foregroundColor تلقائي
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final String imagePath;
  
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.imagePath,
  });
}