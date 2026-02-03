import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleAuth(Future<void> Function() method) async {
    setState(() => _isLoading = true);
    try {
      await method();
    } catch (e) {
      _showErrorDialog('Security Alert', 'Access denied or authentication failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);

    return CupertinoPageScaffold(
      backgroundColor: AdminTheme.surfaceWhite,
      child: Stack(
        children: [
          // Background Gradient accent
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AdminTheme.primaryBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AdminTheme.blueGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AdminTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_shield_fill,
                      size: 50,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('IDEADE', style: AdminTheme.heading1),
                  const Text('CONTROL CENTER', 
                    style: TextStyle(
                      letterSpacing: 4, 
                      fontSize: 12, 
                      fontWeight: FontWeight.w800, 
                      color: AdminTheme.textGrey
                    )
                  ),
                  const SizedBox(height: 60),
                  
                  if (_isLoading)
                    const CupertinoActivityIndicator(radius: 16)
                  else ...[
                    _buildAuthButton(
                      label: 'Administrator Sign-In',
                      onPressed: () => _handleAuth(authService.signInWithGoogle),
                      icon: CupertinoIcons.person_crop_circle_fill,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 16),
                    _buildAuthButton(
                      label: 'Apple Secure Login',
                      onPressed: () => _handleAuth(authService.signInWithApple),
                      icon: CupertinoIcons.device_phone_portrait,
                    ),
                  ],
                  
                  const SizedBox(height: 60),
                  const Icon(CupertinoIcons.shield_lefthalf_fill, size: 24, color: AdminTheme.textLightGrey),
                  const SizedBox(height: 16),
                  const Text(
                    'SECURE END-TO-END ENCRYPTED SYSTEM\nLEVEL 4 ACCESS REQUIRED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textLightGrey,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required String label, 
    required VoidCallback onPressed, 
    required IconData icon,
    bool isPrimary = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary ? AdminTheme.textBlack : AdminTheme.surfaceGrey,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary ? AdminTheme.cardShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isPrimary ? CupertinoColors.white : AdminTheme.textBlack),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isPrimary ? CupertinoColors.white : AdminTheme.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
