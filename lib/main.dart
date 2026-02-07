// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_wallet/core/services/theme_service.dart';
import 'package:my_wallet/core/themes/app_theme.dart';
import 'package:my_wallet/core/utils/language_service.dart';
import 'package:my_wallet/core/utils/navigation_service.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/auth/presentation/screens/email_screen.dart';
import 'package:my_wallet/features/auth/presentation/screens/passcode_screen.dart';
import 'package:my_wallet/features/auth/presentation/screens/pin_screen.dart';
import 'package:my_wallet/features/auth/presentation/screens/register_screen.dart';
import 'package:my_wallet/features/auth/presentation/screens/verification_screen.dart';
import 'package:my_wallet/features/home/presentation/screens/HomeScreen.dart';
import 'package:my_wallet/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:my_wallet/features/splash/presentation/screens/splash_screen.dart';
import 'package:my_wallet/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  await SharedPrefs.init();
  await ThemeService.init();
  await LanguageService.init();
  
  runApp(const MyWalletApp());
}

class MyWalletApp extends StatefulWidget {
  const MyWalletApp({super.key});
  
  @override
  State<MyWalletApp> createState() => _MyWalletAppState();
}

class _MyWalletAppState extends State<MyWalletApp> {
  // متغير لتتبع تغييرات اللغة
  Locale _currentLocale = LanguageService.english;

  @override
  void initState() {
    super.initState();
    _loadInitialLocale();
    
    // الاستماع لتغييرات اللغة
    LanguageService.localeNotifier.addListener(_onLocaleChanged);
    
    // الاستماع لتغييرات الثيم
    ThemeService.themeNotifier.addListener(() {
      if (mounted) setState(() {});
    });
  }
  
  Future<void> _loadInitialLocale() async {
    final savedLocale = await LanguageService.getSavedLocale();
    if (mounted) {
      setState(() {
        _currentLocale = savedLocale;
      });
    }
  }
  
  void _onLocaleChanged() {
    if (mounted) {
      setState(() {
        _currentLocale = LanguageService.localeNotifier.value;
      });
    }
  }
  
  @override
  void dispose() {
    LanguageService.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }
    void _changeLocale(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
    LanguageService.saveLocale(locale);
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Mahfazati',
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService.navigatorKey,
          locale: _currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ar', 'SA'),
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: SplashScreen(onLocaleChanged: (locale) {
            setState(() {
              _currentLocale = locale;
            });
          }),
          builder: (context, child) {
            final isRTL = _currentLocale.languageCode == 'ar';
            
            return Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0,
                ),
                child: child!,
              ),
            );
          },
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (context) => SplashScreen(onLocaleChanged: _changeLocale),
                );
              case '/onboarding':
                return MaterialPageRoute(
                  builder: (context) => OnboardingScreen(onLocaleChanged: _changeLocale),
                );
              case '/email':
                return MaterialPageRoute(
                  builder: (context) => const EmailScreen(),
                );
              case '/verification':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => VerificationScreen(
                    email: args['email'],
                    isLogin: args['isLogin'],
                  ),
                );
              case '/passcode':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => PasscodeScreen(
                    email: args['email'],
                    verificationCode: args['verificationCode'],
                    isLogin: args['isLogin'],
                  ),
                );
              case '/register':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => RegisterScreen(
                    email: args['email'],
                    verificationCode: args['verificationCode'],
                    passcode: args['passcode'],
                  ),
                );
              case '/home':
                return MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                );
              case '/pin':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => PinScreen(
                    isFirstTime: args?['isFirstTime'] ?? false,
                  ),
                );
              default:
                return MaterialPageRoute(
                  builder: (context) => SplashScreen(onLocaleChanged: _changeLocale),
                );
            }
          },
        );
      },
    );
  }
}