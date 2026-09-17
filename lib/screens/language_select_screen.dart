import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festive_glow.dart';
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

const _cardGradients = [
  [AppColors.secondary, AppColors.primary],
  [Color(0xFF6FA8E8), Color(0xFF3D6FC2)],
  [Color(0xFF2E9B55), Color(0xFF1F6E3C)],
  [Color(0xFFE53935), Color(0xFFF4B942)],
];

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  // The API's fixed set (§3), shown only if `GET /v1/languages` fails
  // (offline on first-ever launch) — otherwise replaced by the real
  // response (APP-CHANGES-01 §7).
  static const _fallbackOptions = [
    _Option('hi', 'हिन्दी'),
    _Option('en', 'English'),
    _Option('mr', 'मराठी'),
  ];

  // Default selection — pre-picked so "आगे बढ़ें" works even if the user
  // never taps a card; they only need to tap if they want something else.
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
      body: Stack(
        children: [
          const Positioned(top: -40, right: -50, child: FestiveGlow(size: 220)),
          const Positioned(
            bottom: 40,
            left: -50,
            child: FestiveGlow(size: 180, color: AppColors.secondary),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(AppIcons.language, size: 26, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.05,
                      children: [
                        for (var i = 0; i < _options.length; i++)
                          _LanguageCard(
                            option: _options[i],
                            gradient: _cardGradients[i % _cardGradients.length],
                            selected: _options[i].code == _selected,
                            onTap: () => setState(() => _selected = _options[i].code),
                          ),
                      ],
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
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final _Option option;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.option,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? gradient.last : AppColors.textPrimary)
                  .withValues(alpha: selected ? 0.3 : 0.05),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative watermark — the language's own first letter,
            // oversized and faint, in place of a real illustration.
            Positioned(
              right: -14,
              bottom: -26,
              child: Text(
                option.label.substring(0, 1),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 92,
                  fontWeight: FontWeight.w800,
                  color: (selected ? Colors.white : AppColors.primary)
                      .withValues(alpha: selected ? 0.16 : 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.25) : AppColors.lightAccent,
                      shape: BoxShape.circle,
                    ),
                    child: selected
                        ? const Icon(AppIcons.free, size: 14, color: Colors.white)
                        : null,
                  ),
                  Text(
                    option.label,
                    style: AppTextStyles.cardTitle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ).copyWith(fontSize: 19),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
