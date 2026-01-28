import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:my_wallet/features/onboarding/presentation/widgets/language_switch.dart';
import 'package:my_wallet/features/onboarding/presentation/widgets/story_progress_bar.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  
  const OnboardingScreen({super.key, required this.onLocaleChanged});
  
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> 
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  Timer? _autoSkipTimer;
  int _currentPage = 0;
  bool _isAnimating = false;
  
  List<OnboardingPageData> _getPages(BuildContext context) {
    final l10n = context.l10n;
    
    return [
      OnboardingPageData(
        title: l10n.welcome,
        description: l10n.welcomeDescription,
        icon: Icons.wallet,
        imagePath: 'assets/images/onboarding_1.svg',
      ),
      OnboardingPageData(
        title: l10n.trackEveryMove,
        description: l10n.trackDescription,
        icon: Icons.track_changes,
        imagePath: 'assets/images/onboarding_2.svg',
      ),
      OnboardingPageData(
        title: l10n.planYourFuture,
        description: l10n.planDescription,
        icon: Icons.insights,
        imagePath: 'assets/images/onboarding_3.svg',
      ),
      OnboardingPageData(
        title: l10n.keepYourSavings,
        description: l10n.keepDescription,
        icon: Icons.savings,
        imagePath: 'assets/images/onboarding_4.svg',
      ),
      OnboardingPageData(
        title: l10n.controlYourExpenses,
        description: l10n.controlDescription,
        icon: Icons.bar_chart,
        imagePath: 'assets/images/onboarding_5.svg',
      ),
    ];
  }
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _pageController.addListener(_onPageChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProgressForPage(_currentPage);
    });
  }
  
  void _startProgressForPage(int page) {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (page == _currentPage) {
        _goToNextPageSmooth();
      }
    });
  }
  
  void _goToNextPageSmooth() {
    if (_isAnimating || !_pageController.hasClients) return;
    
    _isAnimating = true;
    int nextPage = (_currentPage + 1) % _getPages(context).length;
    
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ).then((_) {
      setState(() {
        _currentPage = nextPage;
        _isAnimating = false;
      });
      _startProgressForPage(_currentPage);
    });
  }
  
  void _goToNextPage() {
    if (_isAnimating || !_pageController.hasClients) return;
    
    _isAnimating = true;
    int nextPage = (_currentPage + 1) % _getPages(context).length;
    
    _progressController.stop();
    
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ).then((_) {
      setState(() {
        _currentPage = nextPage;
        _isAnimating = false;
      });
      _startProgressForPage(_currentPage);
    });
  }
  
  void _goToPreviousPage() {
    if (_isAnimating || !_pageController.hasClients || _currentPage == 0) return;
    
    _isAnimating = true;
    int prevPage = _currentPage - 1;
    
    _progressController.stop();
    
    _pageController.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ).then((_) {
      setState(() {
        _currentPage = prevPage;
        _isAnimating = false;
      });
      _startProgressForPage(_currentPage);
    });
  }
  
  void _onPageChanged() {
    if (!_pageController.hasClients || _isAnimating) return;
    
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
      _progressController.stop();
      _startProgressForPage(_currentPage);
    }
  }

  Future<void> _onGetStarted() async {
    await SharedPrefs.setFirstTime(false);
    // TODO: Navigate to email screen
    print('Navigate to email screen');
  }
  
  void _handlePageTap(int index) {
    if (_isAnimating) return;
    
    _isAnimating = true;
    _progressController.stop();
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ).then((_) {
      setState(() {
        _currentPage = index;
        _isAnimating = false;
      });
      _startProgressForPage(_currentPage);
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _autoSkipTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final pages = _getPages(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LanguageSwitch(onLocaleChanged: widget.onLocaleChanged),
          ),
        ],
      ),
      body: Column(
        children: [
          // Story Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StoryProgressBar(
              currentPage: _currentPage,
              totalPages: pages.length,
              progressController: _progressController,
              onPageTap: _handlePageTap,
            ),
          ),
          
          // Page View
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return OnboardingPageWidget(data: pages[index]);
                  },
                ),
                
                // Forward tap area (للصفحة التالية)
                if (isRTL)
                  // العربية: الضغط على اليسار يروح للصفحة الجديدة
                  Positioned.fill(
                    left: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _goToNextPage,
                        child: Container(width: 100, color: Colors.transparent),
                      ),
                    ),
                  )
                else
                  // الإنجليزية: الضغط على اليمين يروح للصفحة الجديدة
                  Positioned.fill(
                    right: 0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _goToNextPage,
                        child: Container(width: 100, color: Colors.transparent),
                      ),
                    ),
                  ),
                
                // Backward tap area (للصفحة السابقة)
                if (isRTL)
                  // العربية: الضغط على اليمين يروح للصفحة السابقة
                  Positioned.fill(
                    right: 0,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _currentPage > 0 ? _goToPreviousPage : null,
                        child: Container(width: 100, color: Colors.transparent),
                      ),
                    ),
                  )
                else
                  // الإنجليزية: الضغط على اليسار يروح للصفحة السابقة
                  Positioned.fill(
                    left: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _currentPage > 0 ? _goToPreviousPage : null,
                        child: Container(width: 100, color: Colors.transparent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Get Started Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                  context.l10n.getStarted,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
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