import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/shimmer_box.dart';
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
  final String labelEn;
  const _Option(this.code, this.label, this.labelEn);
}

// (background tint, matching bold text color) per card, cycling — each
// language gets its own light-tint chip with colored text (not plain
// black), so the grid reads as a distinct palette per row instead of
// uniform tiles with one shared text color.
const _cardPalette = [
  (Color(0xFFFBDADA), Color(0xFFDB5C5C)), // rose
  (Color(0xFFEAEAEA), Color(0xFF4A4A4A)), // grey
  (Color(0xFFE7DEF5), Color(0xFF8B6FD9)), // purple
  (Color(0xFFD9F0EA), Color(0xFF2E9E80)), // teal
  (Color(0xFFDCE6F7), Color(0xFF5B8DEF)), // blue
  (Color(0xFFDFE1F5), Color(0xFF6A6FD6)), // indigo
  (Color(0xFFDFF1E1), Color(0xFF43A164)), // green
  (Color(0xFFF7EFD0), Color(0xFFD9A020)), // amber
  (Color(0xFFF6D9DC), Color(0xFFD9536B)), // pink
  (Color(0xFFF0DEF3), Color(0xFFAD54C0)), // magenta
  (Color(0xFFE9D9CE), Color(0xFF9C6B4F)), // brown
];

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  // The API's fixed set (§3), shown only if `GET /v1/languages` fails
  // (offline on first-ever launch) — otherwise replaced by the real
  // response (APP-CHANGES-01 §7).
  static const _fallbackOptions = [
    _Option('hi', 'हिन्दी', 'Hindi'),
    _Option('en', 'English', 'English'),
    _Option('mr', 'मराठी', 'Marathi'),
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
      final options =
          languages.map((l) => _Option(l.code, l.label, l.labelEn)).toList();
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
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('भाषा चुनें', style: AppTextStyles.screenTitle()),
              const SizedBox(height: 2),
              Text('Select your language', style: AppTextStyles.secondary()),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: _bootstrapping
                    ? GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 8,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 1.7,
                        ),
                        itemBuilder: (context, i) => AppShimmer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _options.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 1.7,
                        ),
                        itemBuilder: (context, i) => _LanguageCard(
                          option: _options[i],
                          palette: _cardPalette[i % _cardPalette.length],
                          selected: _options[i].code == _selected,
                          onTap: () => setState(() => _selected = _options[i].code),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
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

class _LanguageCard extends StatelessWidget {
  final _Option option;
  final (Color background, Color text) palette;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.option,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final english = option.labelEn;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: palette.$1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.label,
                    style: AppTextStyles.cardTitle()
                        .copyWith(fontSize: 18, color: palette.$2, fontWeight: FontWeight.w700),
                  ),
                  if (english != option.label) ...[
                    const SizedBox(height: 2),
                    Text(
                      english,
                      style: AppTextStyles.secondary()
                          .copyWith(color: palette.$2.withValues(alpha: 0.65)),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
