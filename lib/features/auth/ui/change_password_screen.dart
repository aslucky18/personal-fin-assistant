import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../records/ui/home_dashboard.dart';

/// Shown immediately after login when must_change_password == true.
/// The user must set a new password before accessing the app.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmController.text.trim();

    if (newPwd.isEmpty || confirmPwd.isEmpty) {
      _showSnack('Please fill in both fields');
      return;
    }
    if (newPwd.length < 8) {
      _showSnack('Password must be at least 8 characters');
      return;
    }
    if (newPwd != confirmPwd) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.changePassword(newPassword: newPwd);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    } catch (e) {
      if (mounted) _showSnack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PopScope(
      canPop: false, // Force them to set a password — no back button
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(220),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_person_rounded, size: 64, color: primary),
                    const SizedBox(height: 24),
                    Text(
                      'Set New Password',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You logged in with a temporary password.\nPlease set a permanent password to continue.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(170),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // New Password
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline, color: primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        helperText: 'At least 8 characters',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(
                          Icons.lock_reset_rounded,
                          color: primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _changePassword(),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Set Password & Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
