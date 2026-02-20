// features/settings/presentation/widgets/settings_content.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/core/services/biometric_service.dart';
import 'package:my_wallet/core/services/theme_service.dart';
import 'package:my_wallet/core/utils/language_service.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';
import 'package:my_wallet/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:my_wallet/features/settings/presentation/screens/app_icon_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsContent extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  
  const SettingsContent({
    super.key,
    required this.onLocaleChanged,
  });

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool _biometricEnabled = false;
  bool _hideBalances = false;
  bool _isEnglish = true;
  String _currentTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // الاستماع لتغييرات الثيم
    ThemeService.themeNotifier.addListener(() {
      if (mounted) {
        _loadCurrentTheme();
      }
    });
  }

  @override
  void dispose() {
    ThemeService.themeNotifier.removeListener(() {});
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // تحميل إعدادات البايومتريك
    final hasSupport = await BiometricService.hasBiometricSupport();
    final isEnabled = await BiometricService.isBiometricEnabled();
    
    // تحميل اللغة الحالية
    final locale = await LanguageService.getSavedLocale();
    
    // تحميل الثيم الحالي
    await _loadCurrentTheme();
    
    setState(() {
      _biometricEnabled = hasSupport && isEnabled;
      _isEnglish = LanguageService.isEnglish(locale);
    });
  }

  Future<void> _loadCurrentTheme() async {
    final theme = await ThemeService.getSavedTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  Future<void> _switchToArabic() async {
    await LanguageService.switchToArabic();
    setState(() {
      _isEnglish = false;
    });
    widget.onLocaleChanged(LanguageService.arabic);
  }

  Future<void> _switchToEnglish() async {
    await LanguageService.switchToEnglish();
    setState(() {
      _isEnglish = true;
    });
    widget.onLocaleChanged(LanguageService.english);
  }

  Future<void> _setTheme(String theme) async {
    await ThemeService.saveTheme(theme);
  }

  // دوال فتح الروابط الخارجية
  Future<void> _openStore() async {
    const appStoreUrl = 'https://apps.apple.com/app/idYOUR_APP_ID';
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';
    
    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
          await launchUrl(Uri.parse(appStoreUrl));
        }
      } else {
        if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
          await launchUrl(Uri.parse(playStoreUrl));
        }
      }
    } catch (e) {
      _showErrorSnackbar('${context.l10n.cannotOpenStore}: $e');
    }
  }

  Future<void> _openFacebook() async {
    const url = 'https://facebook.com/YOUR_PAGE';
    await _launchUrl(url);
  }

  Future<void> _openTwitter() async {
    const url = 'https://twitter.com/YOUR_PAGE';
    await _launchUrl(url);
  }

  Future<void> _openInstagram() async {
    const url = 'https://instagram.com/YOUR_PAGE';
    await _launchUrl(url);
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://yourwebsite.com/privacy';
    await _launchUrl(url);
  }

  Future<void> _openTerms() async {
    const url = 'https://yourwebsite.com/terms';
    await _launchUrl(url);
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showErrorSnackbar(context.l10n.cannotOpenUrl);
      }
    } catch (e) {
      _showErrorSnackbar('${context.l10n.error}: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.featureComingSoon),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arabic
          _buildLanguageOption(
            label: context.l10n.arabic,
            isSelected: !_isEnglish,
            onTap: _switchToArabic,
            isDarkMode: isDarkMode,
          ),
          
          // English
          _buildLanguageOption(
            label: context.l10n.english,
            isSelected: _isEnglish,
            onTap: _switchToEnglish,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.indigo[800] : Colors.indigo[100])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: isDarkMode ? Colors.indigoAccent : Colors.indigo[600]!,
                  width: 2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDarkMode 
                        ? Colors.indigoAccent.withOpacity(0.3)
                        : Colors.indigoAccent.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.indigo[800])
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  // دالة لفتح modal اختيار الثيم
  void _showThemeSelectionModal() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.selectDisplayTheme,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOptionInModal(
                icon: Icons.light_mode_outlined,
                label: context.l10n.light,
                value: ThemeService.light,
                isSelected: _currentTheme == ThemeService.light,
                iconColor: Colors.orange[700],
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildThemeOptionInModal(
                icon: Icons.dark_mode_outlined,
                label: context.l10n.dark,
                value: ThemeService.dark,
                isSelected: _currentTheme == ThemeService.dark,
                iconColor: Colors.blueGrey[400],
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildThemeOptionInModal(
                icon: Icons.settings_suggest_outlined,
                label: context.l10n.system,
                value: ThemeService.system,
                isSelected: _currentTheme == ThemeService.system,
                iconColor: Colors.grey[600],
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionInModal({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
    required Color? iconColor,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () {
        _setTheme(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blueGrey[800] : Colors.blueGrey[100])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.blueAccent : Colors.blue[600]!)
                : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? (isDarkMode ? Colors.white : Colors.blue[800])
                  : iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDarkMode ? Colors.white : Colors.blue[800])
                      : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDarkMode ? Colors.blueAccent : Colors.blue[600],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Widget لعرض زر الثيم الحالي
  Widget _buildThemeButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String currentThemeLabel = '';
    IconData currentThemeIcon = Icons.settings_suggest_outlined;
    Color? iconColor = Colors.grey[600];
    
    if (_currentTheme == ThemeService.light) {
      currentThemeLabel = context.l10n.light;
      currentThemeIcon = Icons.light_mode_outlined;
      iconColor = Colors.orange[700];
    } else if (_currentTheme == ThemeService.dark) {
      currentThemeLabel = context.l10n.dark;
      currentThemeIcon = Icons.dark_mode_outlined;
      iconColor = Colors.blueGrey[400];
    } else {
      currentThemeLabel = context.l10n.system;
      currentThemeIcon = Icons.settings_suggest_outlined;
      iconColor = Colors.grey[600];
    }
    
    return GestureDetector(
      onTap: _showThemeSelectionModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentThemeIcon,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              currentThemeLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileHeader(isDarkMode),
            const SizedBox(height: 32),
            
            // App Section
            _buildAppSettings(isDarkMode),
            const SizedBox(height: 32),
            
            // Profile Settings Section
            _buildProfileSettings(isDarkMode),
            const SizedBox(height: 32),
            
            // Security Section
            _buildSecuritySettings(isDarkMode),
            const SizedBox(height: 32),
            
            // About Us Section
            _buildAboutUsSection(isDarkMode),
            const SizedBox(height: 32),
            
            // Close Account Section
            _buildCloseAccountSection(isDarkMode),
            const SizedBox(height: 32),
            
            // Logout
            _buildLogoutButton(isDarkMode),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@email.com',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileEditScreen(
        onProfileUpdated: () {
          // تحديث البيانات في الهيدر بعد الرجوع
          setState(() {
            // ممكن تعيد تحميل البيانات من SharedPrefs هنا
          });
        },
      ),
    ),
  );
},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n.manage,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.app,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              // App Icon
// في _buildAppSettings، بعد الـ Divider بتاع App Icon
ListTile(
  leading: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.apps,
      color: isDarkMode ? Colors.white : Colors.black,
      size: 20,
    ),
  ),
  title: Text(
    context.l10n.appIcon,
    style: TextStyle(
      color: isDarkMode ? Colors.white : Colors.black,
      fontWeight: FontWeight.w600,
    ),
  ),
  subtitle: Text(
    context.l10n.changeAppIcon,
    style: TextStyle(
      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      fontSize: 12,
    ),
  ),
  trailing: Icon(
    Icons.chevron_right,
    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
    size: 20,
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppIconScreen(),
      ),
    );
  },
),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Display Mode
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dark_mode,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.displayMode,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.l10n.selectDisplayTheme,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: _buildThemeButton(),
              ),
            ],
          ),
        ),
      ],
    );
  }

// في قسم _buildProfileSettings نغير ListTile الخاص بـ App Language

Widget _buildProfileSettings(bool isDarkMode) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.profileSettings,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            // Personal Details
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: isDarkMode ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
              title: Text(
                context.l10n.personalDetails,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                context.l10n.updateYourPersonalInformation,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
              onTap: () {
                _showComingSoonSnackbar();
              },
            ),
            Divider(
              height: 1,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
            
            // App Language - تغيير هنا
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language,
                  color: isDarkMode ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
              title: Text(
                context.l10n.appLanguage,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                context.l10n.changeAppLanguage,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              trailing: _buildLanguageButton(), // تغيير هنا
            ),
          ],
        ),
      ),
    ],
  );
}

// إضافة دالة لعرض زر اللغة الحالي
Widget _buildLanguageButton() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  String currentLanguageLabel = _isEnglish ? context.l10n.english : context.l10n.arabic;
  
  return GestureDetector(
    onTap: _showLanguageSelectionModal,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLanguageLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ],
      ),
    ),
  );
}

// إضافة دالة لفتح modal اختيار اللغة
void _showLanguageSelectionModal() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.selectLanguage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOptionInModal(
              label: context.l10n.arabic,
              value: false,
              isSelected: !_isEnglish,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildLanguageOptionInModal(
              label: context.l10n.english,
              value: true,
              isSelected: _isEnglish,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

// إضافة دالة لعرض خيار اللغة داخل الـ modal
Widget _buildLanguageOptionInModal({
  required String label,
  required bool value,
  required bool isSelected,
  required bool isDarkMode,
}) {
  return GestureDetector(
    onTap: () {
      if (value) {
        _switchToEnglish();
      } else {
        _switchToArabic();
      }
      Navigator.pop(context);
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkMode ? Colors.blueGrey[800] : Colors.blueGrey[100])
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? (isDarkMode ? Colors.blueAccent : Colors.blue[600]!)
              : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.blue[800])
                    : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: isDarkMode ? Colors.blueAccent : Colors.blue[600],
              size: 20,
            ),
        ],
      ),
    ),
  );
}
  Widget _buildSecuritySettings(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.security,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              // Change Passcode
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.changePasscode,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.l10n.updateYour6DigitPasscode,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: () {
                  _showComingSoonSnackbar();
                },
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Sign with Face ID / Fingerprint
              SwitchListTile(
                value: _biometricEnabled,
                onChanged: (value) async {
                  if (value) {
                    final authenticated = await BiometricService.authenticate();
                    if (authenticated) {
                      await BiometricService.enableBiometric();
                      setState(() {
                        _biometricEnabled = true;
                      });
                    }
                  } else {
                    await BiometricService.disableBiometric();
                    setState(() {
                      _biometricEnabled = false;
                    });
                  }
                },
                title: Text(
                  context.l10n.signWithFaceIDFingerprint,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.l10n.useBiometricAuthentication,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Hide Balances
              SwitchListTile(
                value: _hideBalances,
                onChanged: (value) {
                  setState(() {
                    _hideBalances = value;
                  });
                  _showComingSoonSnackbar();
                },
                title: Text(
                  context.l10n.hideBalances,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.l10n.hideYourBalancesForPrivacy,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.visibility_off,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutUsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.aboutUs,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              // Rate us
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_outline,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.rateUsOnAppStorePlayStore,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: _openStore,
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Like us on Facebook
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.thumb_up_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.likeUsOnFacebook,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: _openFacebook,
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Follow us on Twitter
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.public_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.followUsOnTwitter,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: _openTwitter,
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Follow us on Instagram
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.followUsOnInstagram,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: _openInstagram,
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Privacy Policy
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.privacyPolicy,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: _openPrivacyPolicy,
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              
              // Terms & Conditions
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.termsConditions,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                onTap: _openTerms,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloseAccountSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.account,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              // Close Account
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.closeAccount,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.l10n.permanentlyDeleteYourAccount,
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.red,
                  size: 20,
                ),
                onTap: () {
                  _showCloseAccountDialog(isDarkMode);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCloseAccountDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          context.l10n.closeAccount,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          context.l10n.closeAccountConfirmation,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonSnackbar();
            },
            child: Text(
              context.l10n.closeAccount,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _showLogoutDialog(isDarkMode);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          context.l10n.logout,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          context.l10n.logout,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          context.l10n.logoutConfirmation,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text(
              context.l10n.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    // TODO: تسجيل الخروج من API
    await SharedPrefs.removeAuthToken();
    await SharedPrefs.removeUserData();
    
    // إعادة التوجيه لشاشة الدخول
    Navigator.pushNamedAndRemoveUntil(context, '/email', (route) => false);
  }
}