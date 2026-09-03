import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';
import 'root_shell.dart';

/// Second screen shown after the splash — brand intro with a CTA into
/// the app.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const String _illustrationAsset =
      'assets/onboarding_sunset_transparent.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Image.asset(
                'assets/onboading_screen_logo_transparent.png',
                width: 240,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Har Din, Kuch Share Karo',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'अपने विचार, शुभकामनाएं और खास पल सभी के साथ शेयर करें',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: Image.asset(
                  _illustrationAsset,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightAccent,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: const Icon(
                      Icons.wb_twilight,
                      size: 56,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'शुरू करें',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RootShell()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('यह फीचर जल्द आ रहा है')),
                ),
                child: Text(
                  'पहले से अकाउंट है? लॉगिन करें',
                  style: AppTextStyles.secondary(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
