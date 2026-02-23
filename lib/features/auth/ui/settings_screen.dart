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
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
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
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently delete your account and all data',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'This will permanently delete your account and all associated data. This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete Forever'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        try {
                          await authService.deleteUserAccount();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete account: $e'),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
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
