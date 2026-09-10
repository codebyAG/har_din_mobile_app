import 'package:flutter/material.dart';

import '../data/datasources/local/local_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';
import 'language_select_screen.dart';
import 'root_shell.dart';

/// Second screen shown after the splash — brand intro with a CTA into
/// the app. First launch routes through language-select (§5); every
/// launch after that goes straight to the app, since the choice is
/// stored "forever".
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const String _illustrationAsset =
      'assets/onboarding_sunset_transparent.png';

  Future<void> _onStart(BuildContext context) async {
    final hasLanguage = await const LocalStore().getLanguage() != null;
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasLanguage ? const RootShell() : const LanguageSelectScreen(),
      ),
    );
  }

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
                style: AppTextStyles.body(color: AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'अपने विचार, शुभकामनाएं और खास पल सभी के साथ शेयर करें',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary(color: AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700),
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
                      AppIcons.sun,
                      size: 56,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'शुरू करें',
                onPressed: () => _onStart(context),
              ),
              // Login link intentionally removed — v1 has no accounts (§5).
            ],
          ),
        ),
      ),
    );
  }
}
