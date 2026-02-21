import 'package:flutter/material.dart';
import 'package:finanalyzer/core/theme/app_theme.dart';
import 'package:finanalyzer/features/auth/services/auth_service.dart';
import 'package:finanalyzer/features/auth/ui/login_screen.dart';

import 'package:finanalyzer/features/auth/ui/user_profile_screen.dart';
import 'package:finanalyzer/features/auth/models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final authService = AuthService();
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await authService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                // Profile Section
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (_profile != null) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserProfileScreen(profile: _profile!),
                              ),
                            );
                            if (result == true) {
                              _loadProfile();
                            }
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primary,
                          backgroundImage: _profile?.avatarUrl != null
                              ? NetworkImage(_profile!.avatarUrl!)
                              : null,
                          child: _profile?.avatarUrl == null
                              ? Text(
                                  _profile?.fullName.isNotEmpty == true
                                      ? _profile!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _profile?.fullName ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Options
                ListTile(
                  leading: const Icon(
                    Icons.color_lens_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text('Theme'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dark theme is fixed for now!'),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(
                    Icons.security_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text('Security & Privacy'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () {},
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text('Help & Support'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () {},
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),

                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.error,
                  ),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    // Sign out logic.
                    // We could navigate back to Login manually, but Supabase auth state change will be picked up
                    // if we listen to it in main.dart or a wrapper.
                    // But for now we just signOut and then pop to root and replace with auth screen.
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }
}
