import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finanalyzer/core/theme/app_theme.dart';
import 'package:finanalyzer/features/auth/ui/login_screen.dart';
import 'package:finanalyzer/features/records/ui/home_dashboard.dart';
import 'package:finanalyzer/secrets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Finanalyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: session != null ? const HomeDashboard() : const LoginScreen(),
    );
  }
}
