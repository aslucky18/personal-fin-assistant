import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/responsive.dart';
import '../services/auth_service.dart';
import '../../records/ui/home_dashboard.dart';
import 'setup_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();

      // Reset failed-attempt counter on success
      await _authService.recordSuccessfulLogin();

      var profile = await _authService.getCurrentUserProfile();
      if (!mounted) return;

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch profile.')),
        );
        return;
      }

      // Check if account is locked (edge case for accounts with prior lockout)
      final lockedUntil = profile.accountLockedUntil;
      if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
        final mins = lockedUntil.difference(DateTime.now()).inMinutes + 1;
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account locked. Try again in $mins minute(s).'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Attempt to sync Google profile picture if missing
      if (profile.avatarUrl == null || profile.avatarUrl!.isEmpty) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.userMetadata != null) {
          final googleAvatar = user.userMetadata!['avatar_url'] as String?;
          if (googleAvatar != null && googleAvatar.isNotEmpty) {
            // Update silently and get updated profile so we can pass it down
            profile = await _authService.updateProfile(avatarUrl: googleAvatar);
          }
        }
      }

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final hasCompletedLocal =
          prefs.getBool('onboarding_completed_${profile.id}') ?? false;

      bool isProfileSetup =
          profile.gender != null ||
          profile.jobTitle != null ||
          profile.professionalSalary > 0;

      // Route to correct screen
      if (hasCompletedLocal || isProfileSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboard()),
        );
      } else {
        // First-time Google user → profile setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SetupProfileScreen(profile: profile!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg =
            e.toString().contains('canceled') ||
                e.toString().contains('cancelled')
            ? 'Sign-in cancelled.'
            : 'Sign-in failed: ${e.toString()}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withAlpha(50),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          // Main UI
          Center(
            child: ResponsiveBuilder(
              mobile: _buildCard(context, 0, double.infinity),
              tablet: _buildCard(context, 40, 440),
              desktop: _buildCard(context, 40, 440),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, double padding, double maxWidth) {
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: padding),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 72,
                color: primary,
              ),
              const SizedBox(height: 24),
              Text(
                'FinAnalyzer',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your personal finance companion',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withAlpha(170),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Google Sign-In button
              _GoogleSignInButton(
                isLoading: _isLoading,
                onPressed: _signInWithGoogle,
              ),

              const SizedBox(height: 24),
              Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withAlpha(120),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF1F1F1F),
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(30)
                  : Colors.black.withAlpha(20),
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo using coloured text (no asset needed)
                  const _GoogleGLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Renders the coloured Google "G" without needing any asset file.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          // Simple coloured "G" using RichText spans
          Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4), // Google Blue
              ),
            ),
          ),
        ],
      ),
    );
  }
}
