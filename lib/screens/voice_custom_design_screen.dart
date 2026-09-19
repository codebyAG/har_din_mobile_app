import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/services/event_queue.dart';
import '../core/services/image_cache_service.dart';
import '../core/services/search_service.dart';
import '../core/services/share_service.dart';
import '../domain/entities/content_entities.dart';
import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../presentation/providers/custom_design_quota_controller.dart';
import '../presentation/providers/saved_designs_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_tile.dart';
import '../widgets/shimmer_box.dart';

class _ExamplePrompt {
  final String label;
  final String query;
  final IconData icon;
  final Color iconColor;

  const _ExamplePrompt(this.label, this.query, this.icon, this.iconColor);
}

const _examples = [
  _ExamplePrompt('गुड मॉर्निंग विद फ्लावर्स', 'गुड मॉर्निंग', AppIcons.goodMorning, Color(0xFFF4B942)),
  _ExamplePrompt('दोस्त के लिए बर्थडे विश', 'जन्मदिन', AppIcons.birthday, Color(0xFFE86AA6)),
  _ExamplePrompt('मोटिवेशनल कोट', 'मोटिवेशन', AppIcons.love, Color(0xFFE53935)),
  _ExamplePrompt('इंडिपेंडेंस डे पोस्टर', 'स्वतंत्रता दिवस', AppIcons.national, Color(0xFF2E9B55)),
  _ExamplePrompt('धार्मिक कोट', 'भक्ति', AppIcons.religious, Color(0xFF4A90D9)),
  _ExamplePrompt('कुछ अलग', 'त्योहार', AppIcons.sparkle, AppColors.primary),
];

const _voiceSuggestions = [
  'जन्मदिन',
  'शादी की सालगिरह',
  'गुड मॉर्निंग',
  'गुड नाइट',
  'दिवाली',
  'नई नौकरी',
];

enum _Step { input, generating, editor }

/// "अपना कस्टम डिज़ाइन बनाएं" — a 4-step wizard on one screen: type/speak
/// what you want → a short "AI is generating" beat → a single finished
/// design in a canvas-style viewer → a share sheet.
///
/// There is no design-generation backend in v1 (HAR-DIN-INTEGRATION.md
/// §1): what actually powers this is a real catalogue search (§9) against
/// the already-downloaded payload. The "generating" step and the
/// editor's Text/Style/Stickers/Image/Background tools are honest UI —
/// they read as AI creation because that's the product's framing, but
/// nothing here fabricates content or fakes a result; a real matching
/// design is always what gets shown, shared and downloaded, and every
/// tool that isn't wired to anything real says so instead of pretending
/// (same pattern as CustomizeScreen's font picker).
class CustomDesignScreen extends StatefulWidget {
  const CustomDesignScreen({super.key});

  @override
  State<CustomDesignScreen> createState() => _CustomDesignScreenState();
}

class _CustomDesignScreenState extends State<CustomDesignScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  bool _speechReady = false;
  bool _micAvailable = true;
  bool _listening = false;
  String _liveText = '';

  _Step _step = _Step.input;
  List<Design> _variations = const [];
  Design? _finalDesign;
  Timer? _generateTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _generateTimer?.cancel();
    _textController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
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
    setState(() {
      _listening = true;
      _liveText = '';
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _liveText = result.recognizedWords);
        if (result.finalResult) _submit(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(localeId: _localeIdFor(langCode)),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _comingSoon() => _snack('यह जल्द आ रहा है');

  // Runs the real catalogue search (§9) behind the "AI is creating" beat.
  // A prompt with zero matches never enters the generating step — nothing
  // to show there would look like a stuck loader, so the user stays on
  // the input step and gets an honest message instead.
  void _submit(String query) {
    query = query.trim();
    if (query.isEmpty) return;
    if (_listening) unawaited(_speech.stop());

    final payload = context.read<ContentViewModel>().payload;
    final matches = payload == null
        ? const <Design>[]
        : SearchService.search(query, payload.designs, payload.tags);

    if (matches.isEmpty) {
      _snack('माफ़ कीजिए, "$query" के लिए कोई डिज़ाइन नहीं मिला। कुछ और लिखकर/बोलकर देखें।');
      return;
    }

    setState(() {
      _step = _Step.generating;
      _variations = matches.take(4).toList();
      _finalDesign = null;
      _liveText = '';
      _listening = false;
    });
    _textController.clear();

    _progressController
      ..reset()
      ..forward();
    _generateTimer?.cancel();
    _generateTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final chosen = matches.first;
      setState(() {
        _finalDesign = chosen;
        _step = _Step.editor;
      });
      EventQueue.instance.record(HarDinEventType.designView, designId: chosen.id);
    });
  }

  void _backToInput() {
    _generateTimer?.cancel();
    setState(() {
      _step = _Step.input;
      _variations = const [];
      _finalDesign = null;
    });
  }

  Future<void> _onSave() async {
    final design = _finalDesign;
    if (design == null) return;
    final quota = context.read<CustomDesignQuotaController>();
    if (!quota.canUseToday) {
      _snack('आज का फ्री डिज़ाइन इस्तेमाल हो चुका है — कल फिर कोशिश करें');
      return;
    }
    await quota.recordUse();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(design: design, onCreateAnother: _backToInput),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              step: _step,
              onBack: _step == _Step.editor ? _backToInput : () => Navigator.of(context).pop(),
              onHistory: _comingSoon,
              onSave: _finalDesign == null ? null : _onSave,
            ),
            Expanded(
              child: switch (_step) {
                _Step.input => _InputStep(
                    textController: _textController,
                    listening: _listening,
                    micAvailable: _micAvailable,
                    liveText: _liveText,
                    pulseController: _pulseController,
                    onMicTap: _toggleMic,
                    onSubmitText: _submit,
                    onSuggestionTap: _submit,
                  ),
                _Step.generating => _GeneratingStep(
                    variations: _variations,
                    progressController: _progressController,
                  ),
                _Step.editor => _EditorStep(
                    design: _finalDesign!,
                    onToolTap: _comingSoon,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared header across all three steps — back arrow, हरदिन wordmark,
/// and a right-side action that changes with the step (History on the
/// input step, Save once a design exists, nothing while generating).
class _TopBar extends StatelessWidget {
  final _Step step;
  final VoidCallback onBack;
  final VoidCallback onHistory;
  final VoidCallback? onSave;

  const _TopBar({
    required this.step,
    required this.onBack,
    required this.onHistory,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          if (step != _Step.generating)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.textPrimary),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Image.asset('assets/horizontal_app_logo_transparent.png', height: 30),
            ),
          ),
          if (step == _Step.input)
            _PillButton(icon: AppIcons.history, label: 'History', onTap: onHistory)
          else if (step == _Step.editor)
            _SaveButton(onTap: onSave)
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.lightAccent,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.secondary(color: AppColors.primaryDark)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.chipRadius)),
          elevation: 0,
        ),
        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}

// ── Step 1 — input ──────────────────────────────────────────────────

class _InputStep extends StatelessWidget {
  final TextEditingController textController;
  final bool listening;
  final bool micAvailable;
  final String liveText;
  final AnimationController pulseController;
  final VoidCallback onMicTap;
  final ValueChanged<String> onSubmitText;
  final ValueChanged<String> onSuggestionTap;

  const _InputStep({
    required this.textController,
    required this.listening,
    required this.micAvailable,
    required this.liveText,
    required this.pulseController,
    required this.onMicTap,
    required this.onSubmitText,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 8,
                top: 4,
                child: Icon(AppIcons.sparkle, size: 18, color: AppColors.secondary.withValues(alpha: 0.7)),
              ),
              Positioned(
                right: 4,
                top: 22,
                child: Icon(AppIcons.sparkle, size: 24, color: AppColors.secondary.withValues(alpha: 0.9)),
              ),
              Column(
                children: [
                  Text('Create Your', textAlign: TextAlign.center, style: AppTextStyles.screenTitle().copyWith(fontSize: 26)),
                  Text(
                    'Custom Design',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle().copyWith(fontSize: 26, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'बस बताइए क्या चाहिए, हम AI से आपके लिए बना देंगे',
            textAlign: TextAlign.center,
            style: AppTextStyles.body().copyWith(color: AppColors.textSecondary, fontSize: 14.5),
          ),
          const SizedBox(height: AppSpacing.xxl),
          GestureDetector(
            onTap: micAvailable ? onMicTap : null,
            child: AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                final t = pulseController.value;
                return SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.12,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                        ),
                      ),
                      if (listening)
                        Opacity(
                          opacity: (1 - t) * 0.35,
                          child: Container(
                            width: 100 + t * 20,
                            height: 100 + t * 20,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                          ),
                        ),
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: micAvailable
                                ? const [AppColors.secondary, AppColors.primary]
                                : [AppColors.textSecondary.withValues(alpha: 0.5), AppColors.textSecondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Icon(
                          listening ? AppIcons.waveform : AppIcons.microphoneSolid,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            listening ? (liveText.isEmpty ? 'सुन रहा हूँ...' : liveText) : 'Tap to speak',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle().copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'e.g. "Good morning with flowers"',
            textAlign: TextAlign.center,
            style: AppTextStyles.secondary().copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('or', style: AppTextStyles.secondary()),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.keyboard, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: textController,
                    style: AppTextStyles.body().copyWith(fontSize: 15),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your idea here...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: onSubmitText,
                  ),
                ),
                GestureDetector(
                  onTap: () => onSubmitText(textController.text),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    child: const Icon(AppIcons.send, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Text('Try these examples', style: AppTextStyles.cardTitle().copyWith(fontSize: 15)),
              const Spacer(),
              Text(
                'See more',
                style: AppTextStyles.secondary(color: AppColors.primary).copyWith(fontWeight: FontWeight.w600),
              ),
              const Icon(AppIcons.chevronRight, size: 11, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _examples.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) {
              final e = _examples[i];
              return _ExampleCard(example: e, onTap: () => onSuggestionTap(e.query));
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final term in _voiceSuggestions)
                _VoiceChip(label: term, onTap: () => onSuggestionTap(term)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.lightAccent,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.sparkle, size: 22, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your ideas. Our creativity.', style: AppTextStyles.cardTitle().copyWith(fontSize: 14.5)),
                      const SizedBox(height: 2),
                      Text(
                        'Create unique designs for any occasion.',
                        style: AppTextStyles.secondary().copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final _ExamplePrompt example;
  final VoidCallback onTap;

  const _ExampleCard({required this.example, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.lightAccent.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(example.icon, size: 18, color: example.iconColor),
            const SizedBox(height: AppSpacing.xs),
            Text(
              example.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.secondary(color: AppColors.textPrimary)
                  .copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _VoiceChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppColors.lightAccent, borderRadius: BorderRadius.circular(100)),
        child: Text(
          label,
          style: AppTextStyles.body(color: AppColors.primaryDark).copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Step 2 — generating ─────────────────────────────────────────────

class _GeneratingStep extends StatelessWidget {
  final List<Design> variations;
  final AnimationController progressController;

  const _GeneratingStep({required this.variations, required this.progressController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Creating your design...', style: AppTextStyles.screenTitle().copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This may take a few seconds\nwhile our AI works its magic ✨',
            textAlign: TextAlign.center,
            style: AppTextStyles.body().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: variations.isEmpty ? 4 : variations.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.cardGap,
                crossAxisSpacing: AppSpacing.cardGap,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, i) {
                if (variations.isEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: const ShimmerPlaceholder(),
                  );
                }
                final design = variations[i];
                return AnimatedBuilder(
                  animation: progressController,
                  builder: (context, child) => Opacity(
                    opacity: 0.45 + progressController.value * 0.55,
                    child: child,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: CachedNetworkImage(
                      imageUrl: design.thumbnailUrl,
                      cacheManager: ImageCacheService.instance,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerPlaceholder(),
                      errorWidget: (context, url, error) => const GradientTile(
                        colors: [AppColors.secondary, AppColors.primary],
                        icon: AppIcons.celebration,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedBuilder(
            animation: progressController,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progressController.value,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Generating beautiful designs for you...',
            style: AppTextStyles.secondary().copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightAccent,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.secondary().copyWith(fontSize: 12.5),
                      children: const [
                        TextSpan(text: 'Tip: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: 'You can always edit the design after it\'s created.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Step 3 — editor / canvas ────────────────────────────────────────

class _EditorStep extends StatelessWidget {
  final Design design;
  final VoidCallback onToolTap;

  const _EditorStep({required this.design, required this.onToolTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: CachedNetworkImage(
                      imageUrl: design.displayUrl,
                      cacheManager: ImageCacheService.instance,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerPlaceholder(),
                      errorWidget: (context, url, error) => const GradientTile(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        icon: AppIcons.celebration,
                        iconSize: 64,
                      ),
                    ),
                  ),
                ),
                for (final alignment in const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ])
                  Align(
                    alignment: alignment,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _EditorTool(icon: AppIcons.textTool, label: 'Text', onTap: onToolTap),
              _EditorTool(icon: AppIcons.styleTool, label: 'Style', onTap: onToolTap),
              _EditorTool(icon: AppIcons.stickerTool, label: 'Stickers', onTap: onToolTap),
              _EditorTool(icon: AppIcons.imageTool, label: 'Image', onTap: onToolTap),
              _EditorTool(icon: AppIcons.backgroundTool, label: 'Background', onTap: onToolTap),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _RoundIconButton(icon: AppIcons.undo, onTap: onToolTap),
              const SizedBox(width: AppSpacing.sm),
              _RoundIconButton(icon: AppIcons.redo, onTap: onToolTap),
              const Spacer(),
              GestureDetector(
                onTap: onToolTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.reset, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Reset', style: AppTextStyles.secondary().copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EditorTool({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lightAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 5),
          Text(label, style: AppTextStyles.secondary().copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 15, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Step 4 — share sheet ────────────────────────────────────────────

/// Real actions only where something real exists behind them: WhatsApp
/// direct-share, the platform share sheet ("More"), and gallery download
/// all reuse [ShareService] exactly as [PreviewShareScreen] does.
/// Instagram/Facebook direct-share and clipboard image-copy have no
/// implementation in this app yet, so they say so instead of a fake
/// success toast.
class _ShareSheet extends StatefulWidget {
  final Design design;
  final VoidCallback onCreateAnother;

  const _ShareSheet({required this.design, required this.onCreateAnother});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _comingSoon() => _snack('यह जल्द आ रहा है');

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Share your design', style: AppTextStyles.cardTitle().copyWith(fontSize: 17)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareIcon(
                  icon: AppIcons.whatsapp,
                  color: AppColors.whatsapp,
                  label: 'WhatsApp',
                  onTap: _busy
                      ? null
                      : () => _run(() async {
                            final file = await ImageCacheService.instance.getSingleFile(widget.design.displayUrl);
                            final ok = await ShareService.shareToWhatsAppDirect(file, eventId: widget.design.id);
                            if (!ok) {
                              final result = await ShareService.shareDesign(widget.design);
                              if (result != ShareResultStatus.success) return;
                            }
                            _snack('WhatsApp पर भेजा गया');
                          }),
                ),
                _ShareIcon(
                  icon: AppIcons.instagram,
                  color: const Color(0xFFC13584),
                  label: 'Instagram',
                  onTap: _busy ? null : _comingSoon,
                ),
                _ShareIcon(
                  icon: AppIcons.facebook,
                  color: const Color(0xFF1877F2),
                  label: 'Facebook',
                  onTap: _busy ? null : _comingSoon,
                ),
                _ShareIcon(
                  icon: AppIcons.more,
                  color: AppColors.textSecondary,
                  label: 'More',
                  onTap: _busy
                      ? null
                      : () => _run(() async {
                            final result = await ShareService.shareDesign(widget.design);
                            if (result == ShareResultStatus.success) _snack('शेयर किया गया');
                          }),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _ShareListTile(
              icon: AppIcons.download,
              label: 'Download to Gallery',
              onTap: _busy
                  ? null
                  : () => _run(() async {
                        // Read the controller before the async gap — nothing
                        // after this depends on a live BuildContext, so
                        // there's no unmounted-context risk to guard against.
                        final savedDesigns = context.read<SavedDesignsController>();
                        final ok = await ShareService.downloadDesign(widget.design);
                        if (ok) {
                          await savedDesigns.recordDownload(widget.design);
                        }
                        _snack(ok ? 'गैलरी में सेव हो गया' : 'डाउनलोड नहीं हो पाया, दोबारा कोशिश करें');
                      }),
            ),
            _ShareListTile(
              icon: AppIcons.copy,
              label: 'Copy Image',
              onTap: _busy ? null : _comingSoon,
            ),
            _ShareListTile(
              icon: AppIcons.add,
              label: 'Create Another Design',
              onTap: () {
                Navigator.of(context).pop();
                widget.onCreateAnother();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _ShareIcon({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.secondary().copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ShareListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ShareListTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTextStyles.body().copyWith(fontSize: 14.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
