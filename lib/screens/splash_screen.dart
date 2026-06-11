import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_provider.dart';
import '../widgets/animated_loader.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';
import 'admin_panel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startLaunchRoutine();
  }

  Future<void> _startLaunchRoutine() async {
    // Elegant launch delay for branding impression
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch_done') ?? false;

    if (!isFirstLaunch) {
      // Direct new users to onboarding
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      // Evaluate session details for returning users
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      // Wait for Firebase Auth listener to initialize
      while (!auth.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final isAdmin = auth.currentUser?.role == 'admin';
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            if (!auth.isAuthenticated) return const LoginScreen();
            return isAdmin ? const AdminPanel() : const HomeScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedLoader(
                size: 80,
                message: 'BabyShopHub',
              ),
              const SizedBox(height: 12),
              Text(
                'Care. Comfort. Joy.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onBackground.withOpacity(0.4),
                  letterSpacing: 1.2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
