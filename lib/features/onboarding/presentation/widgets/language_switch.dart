import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/core/utils/language_service.dart';
import 'package:my_wallet/l10n/app_localizations.dart';

class LanguageSwitch extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  
  const LanguageSwitch({super.key, required this.onLocaleChanged});
  
  @override
  State<LanguageSwitch> createState() => _LanguageSwitchState();
}

class _LanguageSwitchState extends State<LanguageSwitch> {
  late bool _isEnglish;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }
  
  Future<void> _loadCurrentLanguage() async {
    final locale = await LanguageService.getSavedLocale();
    setState(() {
      _isEnglish = LanguageService.isEnglish(locale);
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
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arabic
          GestureDetector(
            onTap: _switchToArabic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !_isEnglish 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.l10n.arabic,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !_isEnglish
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          
          // English
          GestureDetector(
            onTap: _switchToEnglish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isEnglish 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.l10n.english,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isEnglish
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}