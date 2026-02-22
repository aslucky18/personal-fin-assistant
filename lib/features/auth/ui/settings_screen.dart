import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

import 'user_profile_screen.dart';
import '../models/user_profile.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          backgroundImage: _profile?.avatarUrl != null
                              ? NetworkImage(_profile!.avatarUrl!)
                              : null,
                          child: _profile?.avatarUrl == null
                              ? Text(
                                  _profile?.fullName != null &&
                                          _profile!.fullName!.isNotEmpty
                                      ? _profile!.fullName![0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
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
                  leading: Icon(
                    Icons.color_lens_rounded,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                  title: const Text('Theme'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                  onTap: () {
                    _showThemePicker(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.security_rounded,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                  title: const Text('Security & Privacy'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.help_outline_rounded,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                  title: const Text('Help & Support'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                  ),
                  onTap: () {},
                ),
                const Divider(),
                const SizedBox(height: 24),

                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        ); // Use original context provider directly
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Theme', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppThemeOption.values.length,
                  itemBuilder: (context, index) {
                    final option = AppThemeOption.values[index];
                    final isSelected = themeProvider.currentTheme == option;
                    return ListTile(
                      title: Text(option.name.toUpperCase()),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        themeProvider.setTheme(option);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
