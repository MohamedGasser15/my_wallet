import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:my_wallet/features/wallet/data/models/voice_expense_model.dart';
import 'package:my_wallet/features/wallet/data/repositories/wallet_repository.dart';

class VoiceExpenseButton extends StatefulWidget {
  final Function(VoiceExpenseResult result) onResult;
  final bool isDarkMode;

  const VoiceExpenseButton({
    super.key,
    required this.onResult,
    required this.isDarkMode,
  });

  @override
  State<VoiceExpenseButton> createState() => _VoiceExpenseButtonState();
}

class _VoiceExpenseButtonState extends State<VoiceExpenseButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final WalletRepository _repo = WalletRepository();

  bool _isListening = false;
  bool _isProcessing = false;
  bool _hasProcessed = false; // ✅ الجديد
  String _recognizedText = '';
  bool _speechInitialized = false;

  late bool _isArabic;
  late String _selectedLocale;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final deviceLocale = Platform.localeName;
    _isArabic = deviceLocale.startsWith('ar');
    _selectedLocale = _isArabic ? 'ar_EG' : 'en_US';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _stopAndProcess(); // ✅ محمي بالـ flag جوا
        }
      },
    );
    if (mounted) setState(() => _speechInitialized = available);
  }

  void _toggleLanguage() {
    if (_isListening) return;
    setState(() {
      _isArabic = !_isArabic;
      _selectedLocale = _isArabic ? 'ar_EG' : 'en_US';
    });
  }

  Future<void> _startListening() async {
    if (!_speechInitialized) await _initSpeech();
    if (!_speechInitialized) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _hasProcessed = false; // ✅ reset عند كل تسجيل جديد
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult && !_hasProcessed) { // ✅ شيك
          _stopAndProcess();
        }
      },
      localeId: _selectedLocale,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );
  }

  Future<void> _stopAndProcess() async {
    if (_hasProcessed) return; // ✅ الحماية الرئيسية
    if (!_isListening && _recognizedText.isEmpty) return;

    _hasProcessed = true; // ✅ قبل أي await
    await _speech.stop();

    if (mounted) setState(() { _isListening = false; _isProcessing = true; });

    if (_recognizedText.isNotEmpty) {
  try {
    final result = await _repo.parseVoiceText(
      _recognizedText,
      language: _isArabic ? 'ar' : 'en',
    );
    // ✅ بنبعت النتيجة من غير note
    widget.onResult(VoiceExpenseResult(
      amount: result.amount,
      transactionType: result.transactionType,
      categoryId: result.categoryId,
      categoryNameAr: result.categoryNameAr,
      categoryNameEn: result.categoryNameEn,
      title: result.title,
      note: null, // ✅ دايماً فاضي
      isSuccess: result.isSuccess,
      errorMessage: result.errorMessage,
    ));
  } catch (e) {
    widget.onResult(VoiceExpenseResult(
      isSuccess: false,
      errorMessage: 'فشل الاتصال بالسيرفر',
    ));
  }
}

    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleLanguage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isArabic
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'AR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isArabic
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.grey[500] : Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: 36,
                  decoration: BoxDecoration(
                    color: !_isArabic
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'EN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: !_isArabic
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.grey[500] : Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        GestureDetector(
          onTap: _isListening ? _stopAndProcess : _startListening,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _isListening
                  ? 1.0 + (_pulseController.value * 0.12)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? Colors.red[700]
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    boxShadow: _isListening
                        ? [BoxShadow(
                            color: Colors.red.withOpacity(0.35),
                            blurRadius: 14,
                            spreadRadius: 3,
                          )]
                        : null,
                  ),
                  child: _isProcessing
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        )
                      : Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: _isListening
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black),
                          size: 26,
                        ),
                ),
              );
            },
          ),
        ),

        if (_isListening && _recognizedText.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: Text(
              _recognizedText,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}