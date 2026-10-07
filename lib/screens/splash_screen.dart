import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_widgets.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the login / sign up artwork while the splash is showing, so
    // that screen opens with no image pop-in.
    if (_precached) return;
    _precached = true;
    AuthBackground.precache(context);
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/hardin_splash_bg.png', fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Image.asset(
                    'assets/har_din_app_logo_transparent.png',
                    width: 220,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Har Din, Kuch Share Karo',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const Spacer(flex: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
