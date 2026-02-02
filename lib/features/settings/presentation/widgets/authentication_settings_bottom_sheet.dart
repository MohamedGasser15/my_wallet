// features/settings/presentation/widgets/authentication_settings_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:my_wallet/core/services/biometric_service.dart';
import 'package:my_wallet/core/utils/shared_prefs.dart';

class AuthenticationSettingsBottomSheet extends StatefulWidget {
  const AuthenticationSettingsBottomSheet({super.key});

  @override
  State<AuthenticationSettingsBottomSheet> createState() => 
      _AuthenticationSettingsBottomSheetState();
}

class _AuthenticationSettingsBottomSheetState 
    extends State<AuthenticationSettingsBottomSheet> {
  bool _biometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final hasSupport = await BiometricService.hasBiometricSupport();
    final isEnabled = await BiometricService.isBiometricEnabled();
    
    setState(() {
      _biometricEnabled = hasSupport && isEnabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (value) {
        // Enable biometric
        final authenticated = await BiometricService.authenticate();
        if (authenticated) {
          await BiometricService.enableBiometric();
          setState(() {
            _biometricEnabled = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication enabled'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Disable biometric
        await BiometricService.disableBiometric();
        setState(() {
          _biometricEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePin() async {
    Navigator.pop(context);
    
    // TODO: Navigate to change PIN flow
    // يمكنك إنشاء شاشة لتغيير الـ PIN
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
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
          
          // Title
          Text(
            'Authentication Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Biometric Switch
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use Face ID/Fingerprint to login'),
            trailing: _isLoading
                ? const CircularProgressIndicator()
                : Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
          ),
          
          // Change PIN
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your 6-digit PIN'),
            onTap: _changePin,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          
          const SizedBox(height: 16),
          
          // Close Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}