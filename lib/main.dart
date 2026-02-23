import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/records/ui/home_dashboard.dart';
import 'features/onboarding/ui/onboarding_screen.dart';
import 'secrets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Finanalyzer',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: FutureBuilder<Map<String, dynamic>>(
        future: _checkAppState(session?.user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data ?? {};
          final bool introSeen = data['intro_seen'] ?? false;
          final bool onboardingCompleted =
              data['onboarding_completed'] ?? false;

          if (!introSeen) {
            return const OnboardingScreen();
          }

          if (session != null) {
            if (onboardingCompleted) {
              return const HomeDashboard();
            } else {
              // Make sure to pass a profile here or somehow redirect to login
              // If we know onboarding is incomplete, LoginScreen will handle it
              // in it's own flow when user logs in, but here we can just go to login
              // to be safe if local state says not completed.
              return const LoginScreen();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _checkAppState(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final introSeen = prefs.getBool('intro_seen') ?? false;
    bool onboardingCompleted = false;

    if (userId != null) {
      onboardingCompleted =
          prefs.getBool('onboarding_completed_$userId') ?? false;

      // Ensure verification via backend
      if (!onboardingCompleted) {
        try {
          final profileData = await Supabase.instance.client
              .from('user_profiles')
              .select()
              .eq('id', userId)
              .single();

          // Completeness > 0 means the profile has been set up at least partially
          final bool isComplete =
              (profileData['full_name'] != null) ||
              (profileData['professional_salary'] != null &&
                  profileData['professional_salary'] > 0);

          if (isComplete) {
            onboardingCompleted = true;
            await prefs.setBool('onboarding_completed_$userId', true);
          }
        } catch (_) {
          // If query fails, stick with local state
        }
      }
    }
    return {
      'intro_seen': introSeen,
      'onboarding_completed': onboardingCompleted,
    };
  }
}
