import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'change_password_screen.dart';
import '../../records/ui/home_dashboard.dart';
import 'setup_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: password);

      // Reset failed-attempt counter on success
      await _authService.recordSuccessfulLogin();

      final profile = await _authService.getCurrentUserProfile();
      if (!mounted) return;

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch profile.')),
        );
        return;
      }

      // Check if account is locked (server-authoritative)
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

      // Temp password: check expiry before routing to ChangePasswordScreen
      if (profile.mustChangePassword) {
        final expires = profile.tempPwdExpiresAt;
        if (expires != null && DateTime.now().isAfter(expires)) {
          await _authService.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Temporary password has expired. Please request a new one.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        );
        return;
      }

      if (profile.completeness > 0) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SetupProfileScreen(profile: profile),
          ),
        );
      }
    } catch (e) {
      // Record failed attempt and show contextual feedback
      try {
        final result = await _authService.recordFailedLogin(email);
        final locked = result['locked'] as bool? ?? false;
        final attempts = result['attempts'] as int? ?? 0;
        if (mounted) {
          String msg;
          if (locked) {
            msg = 'Too many failed attempts. Account locked for 6 hours.';
          } else {
            final remaining = (5 - attempts).clamp(0, 5);
            msg = remaining > 0
                ? 'Incorrect password. $remaining attempt(s) remaining before lockout.'
                : 'Login failed.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.toString()}')),
          );
        }
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
          // Background Gradient / Shapes
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
          // Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          // Main UI
          Center(
            child: ResponsiveBuilder(
              mobile: _buildForm(context, 0, double.infinity),
              tablet: _buildForm(context, 40, 450),
              desktop: _buildForm(context, 40, 450),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, double padding, double maxWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: padding),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(200),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your finances',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                      Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color:
                          Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                          Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 20),
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Sign In'),
              ),
              const SizedBox(height: 24),
              // Signup Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
