// features/profile/presentation/screens/profile_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:my_wallet/core/extensions/context_extensions.dart';
import 'package:my_wallet/core/widgets/custom_button.dart';
import 'package:my_wallet/core/widgets/custom_text_field.dart';
import 'package:my_wallet/features/profile/data/repositories/profile_repository.dart';

class ProfileEditScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileEditScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ProfileRepository _profileRepository = ProfileRepository();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getProfile();
      _fullNameController.text = profile.fullName;
      _userNameController.text = profile.userName;
      _phoneController.text = profile.phoneNumber;
      _emailController.text = profile.email;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await _profileRepository.updateProfile(
        fullName: _fullNameController.text.trim(),
        userName: _userNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(context.l10n.profileUpdatedSuccess)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        widget.onProfileUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${context.l10n.failedToUpdateProfile}: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _userNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.personalDetails,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile picture section with creative design
                      _buildProfilePictureSection(theme, isDarkMode),

                      const SizedBox(height: 32),

                      // Form fields with card design
                      _buildAnimatedField(
                        index: 0,
                        child: CustomTextField(
                          controller: _fullNameController,
                          label: l10n.fullName,
                          hintText: l10n.enterFullName,
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: theme.colorScheme.primary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterFullName;
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildAnimatedField(
                        index: 1,
                        child: CustomTextField(
                          controller: _userNameController,
                          label: l10n.userName,
                          hintText: l10n.enterUserName,
                          prefixIcon: Icon(
                            Icons.alternate_email,
                            color: theme.colorScheme.primary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterUserName;
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildAnimatedField(
                        index: 2,
                        child: CustomTextField(
                          controller: _phoneController,
                          label: l10n.phoneNumber,
                          hintText: l10n.enterPhoneNumber,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterPhoneNumber;
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildAnimatedField(
                        index: 3,
                        child: CustomTextField(
                          controller: _emailController,
                          label: l10n.email,
                          hintText: l10n.email,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          enabled: false,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Error message if any
                      if (_errorMessage != null)
                        _buildErrorContainer(theme),

                      const SizedBox(height: 16),

                      // Save button with creative animation
                      _buildSaveButton(theme),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection(ThemeData theme, bool isDarkMode) {
    return Center(
      child: Stack(
        children: [
          // Profile image with gradient border
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.primary.withOpacity(0.5),
                  theme.colorScheme.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3), // border width
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.scaffoldBackgroundColor,
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

         // Camera button with animation
Positioned(
  bottom: 0,
  right: 0,
  child: TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 500),
    curve: Curves.elasticOut,
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.scaffoldBackgroundColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.camera_alt,
              size: 18,
              color: isDarkMode ? Colors.black : Colors.white, // <= هنا
            ),
            padding: EdgeInsets.zero,
            onPressed: () {
              // TODO: Implement image picker
            },
          ),
        ),
      );
    },
  ),
),
        ],
      ),
    );
  }

  Widget _buildAnimatedField({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOutQuad,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildErrorContainer(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: CustomButton(
        text: context.l10n.save,
        onPressed: _saveProfile,
        isLoading: _isSaving,
        backgroundColor: theme.colorScheme.primary,
        textColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}