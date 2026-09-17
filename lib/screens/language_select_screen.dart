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

// English name shown as the small second line under each card's own
// script — purely cosmetic, so an unlisted code just shows one line.
const _englishNames = {
  'hi': 'Hindi',
  'en': 'English',
  'mr': 'Marathi',
  'ta': 'Tamil',
  'te': 'Telugu',
  'kn': 'Kannada',
  'ml': 'Malayalam',
  'gu': 'Gujarati',
  'pa': 'Punjabi',
  'bn': 'Bengali',
};

// One flat pastel per card, cycling — not a gradient, not all the same
// color, so the grid reads as a set of distinct chips rather than one
// repeated tile.
const _cardColors = [
  Color(0xFFFBD7CE), // peach
  Color(0xFFEDE6D8), // warm cream
  Color(0xFFD6ECE1), // mint
  Color(0xFFDCE1F0), // periwinkle
  Color(0xFFF6E3B4), // butter
  Color(0xFFDDEFD9), // sage
  Color(0xFFF1D9E8), // blush
  Color(0xFFD8ECEF), // sky
  Color(0xFFF0DCEF), // lilac
  Color(0xFFEAD9C9), // sand
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
              if (_bootstrapping)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _options.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, i) => _LanguageCard(
                      option: _options[i],
                      color: _cardColors[i % _cardColors.length],
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
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.option,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final english = _englishNames[option.code];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.success : Colors.transparent,
            width: 2,
          ),
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
                    style: AppTextStyles.cardTitle().copyWith(fontSize: 18),
                  ),
                  if (english != null && english != option.label) ...[
                    const SizedBox(height: 2),
                    Text(english, style: AppTextStyles.secondary()),
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
