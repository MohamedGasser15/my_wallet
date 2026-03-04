// lib/core/services/message_service.dart

import 'package:flutter/material.dart';
import 'package:my_wallet/core/enums/message_type.dart';
import 'package:my_wallet/core/utils/navigation_service.dart';

class MessageService {
  /// عرض رسالة منبثقة بتصميم رسمي وأنيق
  static void showMessage({
    required String message,
    required MessageType type,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    // اختيار اللون والأيقونة حسب نوع الرسالة
    final (Color backgroundColor, IconData icon) = switch (type) {
      MessageType.success => (const Color(0xFF2E7D32), Icons.check_circle_outline),
      MessageType.error => (const Color(0xFFC62828), Icons.error_outline),
      MessageType.info => (const Color(0xFF1565C0), Icons.info_outline),
      MessageType.warning => (const Color(0xFFEF6C00), Icons.warning_amber_outlined),
    };

    final snackBar = SnackBar(
      content: _buildAnimatedContent(
        context: context,
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        onTap: onTap,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.all(20),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static Widget _buildAnimatedContent({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    VoidCallback? onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دوال مساعدة
  static void showSuccess(String message, {VoidCallback? onTap}) {
    showMessage(message: message, type: MessageType.success, onTap: onTap);
  }

  static void showError(String message, {VoidCallback? onTap}) {
    showMessage(message: message, type: MessageType.error, onTap: onTap);
  }

  static void showInfo(String message, {VoidCallback? onTap}) {
    showMessage(message: message, type: MessageType.info, onTap: onTap);
  }

  static void showWarning(String message, {VoidCallback? onTap}) {
    showMessage(message: message, type: MessageType.warning, onTap: onTap);
  }
}