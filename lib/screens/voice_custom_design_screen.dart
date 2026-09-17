import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/services/search_service.dart';
import '../core/utils/design_mapper.dart';
import '../domain/entities/content_entities.dart';
import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../presentation/providers/custom_design_quota_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/status_grid_card.dart';
import 'preview_share_screen.dart';

const _suggestions = [
  'जन्मदिन',
  'शादी की सालगिरह',
  'गुड मॉर्निंग',
  'गुड नाइट',
  'दिवाली',
  'नई नौकरी',
];

/// "बोलकर या लिखकर डिज़ाइन खोजें" — a full page, not a sheet: the results
/// grid genuinely needs the room. Voice is one option beside typing,
/// never a requirement (same on-device search the search box uses — no
/// search endpoint, no AI backend, §9).
///
/// There is no design-generation backend in v1 — "custom design" means
/// finding and handing over a real matching design from the catalogue,
/// counted against the daily free quota only when the user actually
/// picks one. Every match — even a single one — goes into the results
/// grid rather than auto-opening; the pick is always the user's call.
class CustomDesignScreen extends StatefulWidget {
  const CustomDesignScreen({super.key});

  @override
  State<CustomDesignScreen> createState() => _CustomDesignScreenState();
}

class _CustomDesignScreenState extends State<CustomDesignScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _controller = TextEditingController();
  late final AnimationController _pulseController;

  bool _speechReady = false;
  bool _micAvailable = true;
  bool _listening = false;
  List<Design> _results = const [];
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    setState(() {
      _speechReady = ok;
      _micAvailable = ok;
    });
  }

  String _localeIdFor(String langCode) => switch (langCode) {
        'hi' => 'hi_IN',
        'mr' => 'mr_IN',
        _ => 'en_US',
      };

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      await _initSpeech();
      if (!mounted || !_speechReady) return;
    }
    final langCode = context.read<AppLanguageController>().code;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        if (result.finalResult) _runSearch();
      },
      listenOptions: SpeechListenOptions(localeId: _localeIdFor(langCode)),
    );
  }

  void _useSuggestion(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    _runSearch();
  }

  void _runSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    final payload = context.read<ContentViewModel>().payload;
    final matches = payload == null
        ? const <Design>[]
        : SearchService.search(query, payload.designs, payload.tags);
    setState(() {
      _results = matches.take(12).toList();
      _searched = true;
    });
  }

  Future<void> _pickResult(Design design) async {
    final quota = context.read<CustomDesignQuotaController>();
    if (!quota.canUseToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('आज का फ्री डिज़ाइन इस्तेमाल हो चुका है — कल फिर कोशिश करें'),
        ),
      );
      return;
    }
    await quota.recordUse();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreviewShareScreen(design: design)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quota = context.watch<CustomDesignQuotaController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('कस्टम डिज़ाइन'),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuotaBanner(quota: quota),
              const SizedBox(height: AppSpacing.lg),
              Text('बोलकर या लिखकर डिज़ाइन खोजें', style: AppTextStyles.cardTitle()),
              const SizedBox(height: AppSpacing.xs),
              Text('जैसे "मेरी बेटी का जन्मदिन", या नीचे से चुन लें', style: AppTextStyles.secondary()),
              const SizedBox(height: AppSpacing.md),
              _SearchField(
                controller: _controller,
                listening: _listening,
                pulseController: _pulseController,
                micAvailable: _micAvailable,
                onSubmit: _runSearch,
                onMicTap: _toggleMic,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final term in _suggestions)
                    _SuggestionChip(label: term, onTap: () => _useSuggestion(term)),
                ],
              ),
              if (_searched && _results.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _results.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.cardGap,
                    crossAxisSpacing: AppSpacing.cardGap,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, i) {
                    final design = _results[i];
                    return StatusGridCard(
                      status: DesignMapper.toStatusItem(design),
                      width: double.infinity,
                      onUse: () => _pickResult(design),
                    );
                  },
                ),
              ] else if (_searched && _results.isEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    'कोई मैच नहीं मिला — ऊपर दिए विकल्पों में से चुनें',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.secondary(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotaBanner extends StatelessWidget {
  final CustomDesignQuotaController quota;

  const _QuotaBanner({required this.quota});

  @override
  Widget build(BuildContext context) {
    final canUse = quota.canUseToday;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canUse
              ? const [AppColors.secondary, AppColors.primary]
              : [AppColors.textSecondary.withValues(alpha: 0.6), AppColors.textSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            canUse ? AppIcons.sparkle : AppIcons.lock,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              canUse
                  ? 'आज ${quota.remainingToday}/${CustomDesignQuotaController.freeLimitPerDay} फ्री डिज़ाइन बचा है'
                  : 'आज का फ्री डिज़ाइन इस्तेमाल हो चुका है',
              style: AppTextStyles.secondary(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'पेड 10/दिन जल्द',
              style: AppTextStyles.secondary(color: Colors.white).copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// One unified entry point — type, or tap the mic to dictate into the
/// same field. Voice is an option beside typing, never a requirement.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool listening;
  final bool micAvailable;
  final AnimationController pulseController;
  final VoidCallback onSubmit;
  final VoidCallback onMicTap;

  const _SearchField({
    required this.controller,
    required this.listening,
    required this.micAvailable,
    required this.pulseController,
    required this.onSubmit,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              style: AppTextStyles.body(),
              // The app-wide input theme fills the field and draws its
              // own enabled/focused borders — those have to be switched
              // off explicitly too, not just the top-level `border`, or
              // this Container's own rounded border shows up doubled.
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                hintText: 'जैसे "मेरी बेटी का जन्मदिन"',
              ),
            ),
          ),
          if (micAvailable)
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                final t = pulseController.value;
                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: GestureDetector(
                    onTap: onMicTap,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (listening)
                          Opacity(
                            opacity: (1 - t) * 0.5,
                            child: Container(
                              width: 32 + t * 16,
                              height: 32 + t * 16,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.secondary, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            listening ? AppIcons.waveform : AppIcons.microphoneSolid,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            GestureDetector(
              onTap: onSubmit,
              child: Container(
                margin: const EdgeInsets.all(6),
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lightAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.search, size: 15, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.lightAccent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: AppTextStyles.secondary(color: AppColors.primaryDark)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
