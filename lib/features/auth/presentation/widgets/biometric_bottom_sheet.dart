import 'package:flutter/material.dart';
import 'package:my_wallet/core/services/biometric_service.dart';

class BiometricBottomSheet extends StatefulWidget {
  final String biometricName;
  
  const BiometricBottomSheet({
    super.key,
    required this.biometricName,
  });

  @override
  State<BiometricBottomSheet> createState() => _BiometricBottomSheetState();
}

class _BiometricBottomSheetState extends State<BiometricBottomSheet> {
  bool _isLoading = false;

  Future<void> _enableBiometric() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await BiometricService.enableBiometric();
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // TODO: Show error message
    }
  }

  void _skipBiometric() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    // اختيار الأيقونة المناسبة بناءً على نوع البايومتريك
    IconData iconData;
    if (widget.biometricName.toLowerCase().contains('face')) {
      iconData = Icons.face; // أيقونة Face ID
    } else if (widget.biometricName.toLowerCase().contains('finger')) {
      iconData = Icons.fingerprint; // أيقونة Fingerprint
    } else {
      iconData = Icons.security; // أيقونة افتراضية
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              iconData,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Use ${widget.biometricName}?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            'You can use ${widget.biometricName.toLowerCase()} for faster and more secure login.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Primary Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enableBiometric,
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
                  : Text('Enable ${widget.biometricName}'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Secondary Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _skipBiometric,
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Not now'),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}