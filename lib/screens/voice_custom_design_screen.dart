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

/// The voice "अपना फ्री कस्टम डिज़ाइन बनाएं" flow: user speaks an
/// occasion/message, on-device speech recognition transcribes it, and
/// the transcript is matched against the already-downloaded payload's
/// `tags[]` (§9 — there is no search endpoint, this is the same
/// mechanism as the on-screen search box, just fed by voice).
///
/// There is no design-generation backend in v1 — "custom design" here
/// means finding and handing over a real matching design from the
/// catalogue, counted against the daily free quota when the user
/// actually picks one.
class VoiceCustomDesignScreen extends StatefulWidget {
  const VoiceCustomDesignScreen({super.key});

  @override
  State<VoiceCustomDesignScreen> createState() => _VoiceCustomDesignScreenState();
}

class _VoiceCustomDesignScreenState extends State<VoiceCustomDesignScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  late final AnimationController _pulseController;

  bool _speechReady = false;
  bool _speechUnavailable = false;
  bool _listening = false;
  String _transcript = '';
  List<Design> _results = const [];
  bool _searched = false;
  String? _error;

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
        setState(() {
          _listening = false;
          _error = 'सुनने में दिक्कत हुई, दोबारा कोशिश करें';
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _speechReady = ok;
      _speechUnavailable = !ok;
    });
  }

  String _localeIdFor(String langCode) => switch (langCode) {
        'hi' => 'hi_IN',
        'mr' => 'mr_IN',
        _ => 'en_US',
      };

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      await _initSpeech();
      if (!mounted || !_speechReady) return;
    }
    setState(() {
      _error = null;
      _transcript = '';
      _results = const [];
      _searched = false;
      _listening = true;
    });
    final langCode = context.read<AppLanguageController>().code;
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        if (result.finalResult) _runSearch();
      },
      listenOptions: SpeechListenOptions(localeId: _localeIdFor(langCode)),
    );
  }

  void _runSearch() {
    final query = _transcript.trim();
    if (query.isEmpty) return;
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                0,
              ),
              child: _QuotaBanner(quota: quota),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      'बोलिए किस मौके के लिए डिज़ाइन चाहिए',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardTitle(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Text(
                        'जैसे "मेरी बेटी का जन्मदिन" या "दिवाली की शुभकामनाएं"',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.secondary(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _MicButton(
                      listening: _listening,
                      pulseController: _pulseController,
                      onTap: _toggleListening,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_speechUnavailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        child: Text(
                          'इस डिवाइस पर वॉइस इनपुट उपलब्ध नहीं है, या माइक्रोफ़ोन की अनुमति नहीं मिली।',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.secondary(color: AppColors.like),
                        ),
                      )
                    else if (_error != null)
                      Text(_error!, style: AppTextStyles.secondary(color: AppColors.like))
                    else if (_transcript.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightAccent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '"$_transcript"',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body().copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    if (_searched) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _searched && _results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xxl,
                              ),
                              child: Text(
                                'कोई मैच नहीं मिला — दोबारा बोलकर कोशिश करें',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.secondary(),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _results.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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

class _MicButton extends StatelessWidget {
  final bool listening;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _MicButton({
    required this.listening,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        height: 140,
        child: AnimatedBuilder(
          animation: pulseController,
          builder: (context, child) {
            final t = pulseController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (listening)
                  Opacity(
                    opacity: (1 - t) * 0.5,
                    child: Container(
                      width: 90 + t * 50,
                      height: 90 + t * 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Container(
                  width: 88,
                  height: 88,
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
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    listening ? AppIcons.waveform : AppIcons.microphoneSolid,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
