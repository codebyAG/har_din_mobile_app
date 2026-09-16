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
  // The API's fixed set (§3), shown only if `GET /v1/languages` fails
  // (offline on first-ever launch) — otherwise replaced by the real
  // response (APP-CHANGES-01 §7).
  static const _fallbackOptions = [
    _Option('hi', 'हिन्दी'),
    _Option('en', 'English'),
    _Option('mr', 'मराठी'),
  ];

  List<_Option> _options = _fallbackOptions;
  String _selected = 'hi';
  bool _bootstrapping = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // §7 — a dedicated, tiny endpoint (135 bytes, no `lang` param). No
    // version check, no content fetch, no 22 KB thrown away if the user
    // ends up picking a different language than the one this guessed.
    final languages = await context.read<ContentViewModel>().fetchLanguages();
    if (!mounted) return;
    if (languages.isNotEmpty) {
      final options = languages.map((l) => _Option(l.code, l.label)).toList();
      setState(() {
        _options = options;
        _selected =
            options.any((o) => o.code == 'hi') ? 'hi' : options.first.code;
      });
    }
    setState(() => _bootstrapping = false);
  }

  Future<void> _continue(BuildContext context) async {
    setState(() => _loading = true);
    final languageController = context.read<AppLanguageController>();
    await languageController.setLanguageCode(_selected);
    if (!context.mounted) return;
    // The first real content fetch happens once in RootShell (§4) — not
    // here, so a normal app open is still exactly one load() call.
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
              if (_bootstrapping)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
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
                onPressed: (_loading || _bootstrapping) ? null : () => _continue(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
