import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';
import 'root_shell.dart';

/// New — required by §5. Shown once, before the language is stored;
/// the choice becomes `?lang=` forever, never re-prompted.
class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _Option {
  final String code;
  final String label;
  const _Option(this.code, this.label);
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  // The API's fixed language set (§3) — there is no endpoint to list
  // these before a language is picked, so they're hardcoded here, each
  // in its own script per §5.
  static const _options = [
    _Option('hi', 'हिन्दी'),
    _Option('en', 'English'),
    _Option('mr', 'मराठी'),
  ];

  String _selected = 'hi';
  bool _loading = false;

  Future<void> _continue(BuildContext context) async {
    setState(() => _loading = true);
    final languageController = context.read<AppLanguageController>();
    await languageController.setLanguageCode(_selected);
    if (!context.mounted) return;
    // First real content fetch for this language — forced, since there's
    // no prior stored version to compare against.
    await context.read<ContentViewModel>().load(_selected, forceLanguageSwitch: true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootShell()),
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
              const Spacer(),
              Text('भाषा चुनें', style: AppTextStyles.screenTitle()),
              const SizedBox(height: AppSpacing.xs),
              Text('Choose your language', style: AppTextStyles.secondary()),
              const SizedBox(height: AppSpacing.xxl),
              for (final option in _options)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = option.code),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: option.code == _selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: option.code == _selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(option.label, style: AppTextStyles.cardTitle()),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              PrimaryButton(
                label: _loading ? 'लोड हो रहा है...' : 'आगे बढ़ें',
                onPressed: _loading ? null : () => _continue(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
