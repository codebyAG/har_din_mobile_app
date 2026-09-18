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

/// "बोलकर डिज़ाइन खोजें" — a full page, not a sheet, laid out as a running
/// chat: each thing the user says becomes a message bubble, the app
/// replies with a text bubble (+ a design grid when there are matches),
/// and the mic stays pinned at the bottom so the conversation keeps
/// growing turn after turn instead of resetting each time. Speak-only —
/// this audience won't type, so there's no text field, only the mic and
/// tap-to-say suggestion chips.
///
/// The reply is real, scripted app copy plus a real catalogue search
/// (§9) — never a generated message. There is no design-generation
/// backend in v1: "custom design" means finding and handing over a real
/// matching design, counted against the daily free quota only once the
/// user actually picks one. Every match — even a single one — goes into
/// the results grid rather than auto-opening; the pick is always the
/// user's call.
class CustomDesignScreen extends StatefulWidget {
  const CustomDesignScreen({super.key});

  @override
  State<CustomDesignScreen> createState() => _CustomDesignScreenState();
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final List<Design> designs;

  const _ChatMessage.user(this.text)
      : isUser = true,
        designs = const [];

  const _ChatMessage.agent(this.text, {this.designs = const []}) : isUser = false;
}

class _CustomDesignScreenState extends State<CustomDesignScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _pulseController;

  bool _speechReady = false;
  bool _micAvailable = true;
  bool _listening = false;
  String _liveText = '';
  final List<_ChatMessage> _messages = [];

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
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
        if (result.finalResult) _runSearch(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(localeId: _localeIdFor(langCode)),
    );
  }

  void _useSuggestion(String term) => _runSearch(term);

  // Appends one exchange to the running chat — the user's turn, then the
  // app's scripted reply (+ a real results grid when there are matches).
  // The conversation just keeps growing; nothing here resets on a new
  // search.
  void _runSearch(String query) {
    query = query.trim();
    if (query.isEmpty) return;
    setState(() => _liveText = '');
    final payload = context.read<ContentViewModel>().payload;
    final matches = payload == null
        ? const <Design>[]
        : SearchService.search(query, payload.designs, payload.tags);
    final results = matches.take(12).toList();
    setState(() {
      _messages.add(_ChatMessage.user(query));
      _messages.add(
        results.isEmpty
            ? const _ChatMessage.agent('माफ़ कीजिए, इसके लिए कोई डिज़ाइन नहीं मिला। कुछ और बोलकर देखें।')
            : _ChatMessage.agent(
                'ये लीजिए, "$query" के लिए ${results.length} डिज़ाइन मिले —',
                designs: results,
              ),
      );
    });
    _scrollToBottom();
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
              child: _messages.isEmpty
                  ? _EmptyChatState(onSuggestionTap: _useSuggestion)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.md,
                        AppSpacing.screenPadding,
                        AppSpacing.md,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) => _ChatBubble(
                        message: _messages[i],
                        onPickDesign: _pickResult,
                      ),
                    ),
            ),
            // Pinned mic bar — the conversation keeps growing above it,
            // this stays put so the user can keep talking turn after turn.
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
              ),
              child: _SpeakBar(
                listening: _listening,
                micAvailable: _micAvailable,
                liveText: _liveText,
                pulseController: _pulseController,
                onMicTap: _toggleMic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const _EmptyChatState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              ),
              child: const Icon(AppIcons.microphoneSolid, size: 36, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'बताइए, किसके लिए डिज़ाइन चाहिए?',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle().copyWith(fontSize: 21),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'नीचे माइक दबाकर बोलें',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'या इनमें से किसी एक पर उंगली रखें',
              textAlign: TextAlign.center,
              style: AppTextStyles.body()
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final term in _suggestions)
                  _SuggestionChip(label: term, onTap: () => onSuggestionTap(term)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final ValueChanged<Design> onPickDesign;

  const _ChatBubble({required this.message, required this.onPickDesign});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(AppIcons.sparkle, size: 12, color: Colors.white),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(colors: [AppColors.secondary, AppColors.primary])
                        : null,
                    color: isUser ? null : AppColors.card,
                    border: isUser ? null : Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.body().copyWith(
                      fontSize: 15.5,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message.designs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: message.designs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.cardGap,
                crossAxisSpacing: AppSpacing.cardGap,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, i) {
                final design = message.designs[i];
                return StatusGridCard(
                  status: DesignMapper.toStatusItem(design),
                  width: double.infinity,
                  onUse: () => onPickDesign(design),
                );
              },
            ),
          ],
        ],
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

/// Pinned footer — a tap-to-speak mic plus, while listening, the live
/// interim words right beside it. Compact by design: the conversation
/// above is the focus, this is just the always-available way to add the
/// next turn to it.
class _SpeakBar extends StatelessWidget {
  final bool listening;
  final bool micAvailable;
  final String liveText;
  final AnimationController pulseController;
  final VoidCallback onMicTap;

  const _SpeakBar({
    required this.listening,
    required this.micAvailable,
    required this.liveText,
    required this.pulseController,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = !micAvailable
        ? 'माइक उपलब्ध नहीं है'
        : listening
            ? (liveText.isEmpty ? 'सुन रहा हूँ...' : liveText)
            : 'बोलने के लिए टैप करें';

    return Row(
      children: [
        GestureDetector(
          onTap: micAvailable ? onMicTap : null,
          child: AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final t = pulseController.value;
              return SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (listening)
                      Opacity(
                        opacity: (1 - t) * 0.4,
                        child: Container(
                          width: 62 + t * 16,
                          height: 62 + t * 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    Container(
                      width: 62,
                      height: 62,
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
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        listening ? AppIcons.waveform : AppIcons.microphoneSolid,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body().copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.lightAccent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(color: AppColors.primaryDark)
              .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
