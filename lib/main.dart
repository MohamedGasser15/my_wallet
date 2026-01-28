import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_wallet/core/utils/language_service.dart';
import 'package:my_wallet/core/themes/app_theme.dart';
import 'package:my_wallet/core/utils/navigation_service.dart';
import 'package:my_wallet/features/splash/presentation/screens/splash_screen.dart';
import 'package:my_wallet/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const MyWalletApp());
}

class MyWalletApp extends StatefulWidget {
  const MyWalletApp({super.key});
  
  @override
  State<MyWalletApp> createState() => _MyWalletAppState();
}

class _MyWalletAppState extends State<MyWalletApp> {
  Locale? _locale;
  
  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }
  
  Future<void> _loadSavedLocale() async {
    final savedLocale = await LanguageService.getSavedLocale();
    setState(() {
      _locale = savedLocale;
    });
  }
  
  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LanguageService.saveLocale(locale);
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mahfazati',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      locale: _locale,
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
      themeMode: ThemeMode.system,
      home: SplashScreen(onLocaleChanged: _changeLocale),
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        final isRTL = locale.languageCode == 'ar';
        
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
    );
  }
}