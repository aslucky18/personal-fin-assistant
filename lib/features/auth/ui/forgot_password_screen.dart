import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordReset(email: email);
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(220),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
                ),
              ),
              child: _emailSent ? _buildSuccess(primary) : _buildForm(primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_reset_rounded, size: 64, color: primary),
        const SizedBox(height: 24),
        Text(
          'Forgot Password?',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email and we\'ll send you a link to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withAlpha(170),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined, color: primary),
          ),
          onSubmitted: (_) => _sendResetEmail(),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Link'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _buildSuccess(Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_rounded, size: 72, color: primary),
        const SizedBox(height: 24),
        Text(
          'Temporary Password Sent',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a temporary password to\n${_emailController.text.trim()}\n\nLog in with it and you\'ll be asked to set a new permanent password right away.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withAlpha(170),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Sign In'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('Resend Temp Password'),
        ),
      ],
    );
  }
}
