import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Floral cream-and-orange artwork behind the login / sign up screens.
class AuthBackground extends StatelessWidget {
  static const String asset = 'assets/login_signup_background.png';
  static const String logoAsset = 'assets/horizontal_app_logo_transparent.png';

  final Widget child;

  const AuthBackground({super.key, required this.child});

  // The source PNG is ~1.4 MB — decode at screen size. Preload and build
  // use this same provider so the image cache key matches and the screen
  // opens with the artwork already decoded (no pop-in).
  static ImageProvider _background(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ResizeImage(
      const AssetImage(asset),
      width: (size.width * dpr).round(),
    );
  }

  /// Warm the image cache for the login / sign up screen. Call early
  /// (e.g. from the splash screen); safe to call more than once.
  static Future<void> precache(BuildContext context) async {
    try {
      await Future.wait([
        precacheImage(_background(context), context),
        precacheImage(const AssetImage(logoAsset), context),
      ]);
    } catch (_) {
      // Purely an optimisation — the screen still loads it on demand.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFFFF6E3)),
        Image(
          image: _background(context),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        child,
      ],
    );
  }
}

/// Shared page for the auth screens: floral artwork on top (back arrow,
/// horizontal logo, tagline, one-line pitch) and a white rounded card
/// pinned to the bottom holding [title], [subtitle] and [children].
class AuthPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: IconButton(
                          tooltip: 'वापस जाएं',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Image.asset(AuthBackground.logoAsset, width: 220),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Har Din, Kuch Share Karo ❤️',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(
                        color: AppColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxl,
                      ),
                      child: Text(
                        'Tyohaar, greetings, status aur quotes ko apne '
                        'andaaz mein share karein.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.secondary(),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl + bottomInset,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.10,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.screenTitle().copyWith(
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(subtitle, style: AppTextStyles.secondary()),
                          const SizedBox(height: AppSpacing.xl),
                          ...children,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white, rounded input with a leading icon — hint text only.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: AppTextStyles.body(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.secondary(),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        suffixIcon: suffix,
        fillColor: Colors.white,
      ),
    );
  }
}

/// One-box-per-digit OTP entry. A single invisible [TextField] owns the
/// text (so paste, backspace and SMS autofill all just work); the boxes
/// only display it. Calls [onCompleted] once all [length] digits are in.
class OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final bool enabled;
  final VoidCallback? onCompleted;

  const OtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.onCompleted,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FocusNode _focus = FocusNode();
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final complete = widget.controller.text.length == widget.length;
    if (complete && !_completedFired) {
      _completedFired = true;
      widget.onCompleted?.call();
    } else if (!complete) {
      _completedFired = false;
    }
  }

  void _focusAndShowKeyboard() {
    _focus.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'OTP, ${widget.length} अंक',
      textField: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focusAndShowKeyboard : null,
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([widget.controller, _focus]),
              builder: (context, _) {
                final text = widget.controller.text;
                final active = _focus.hasFocus
                    ? text.length.clamp(0, widget.length - 1)
                    : -1;
                return Row(
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _OtpBox(
                          digit: i < text.length ? text[i] : '',
                          active: i == active,
                          filled: i < text.length,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            // Invisible, but real: it holds focus and the text.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: true,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String digit;
  final bool active;
  final bool filled;

  const _OtpBox({
    required this.digit,
    required this.active,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.primary
              : filled
              ? AppColors.secondary
              : AppColors.border,
          width: active ? 2 : 1.2,
        ),
      ),
      child: Text(
        digit,
        style: AppTextStyles.screenTitle().copyWith(fontSize: 22),
      ),
    );
  }
}

/// A line, some text, a line — "अभी अकाउंट नहीं है? Sign Up करें".
class AuthFooterLink extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          child: Text.rich(
            TextSpan(
              text: '$prompt ',
              style: AppTextStyles.secondary(),
              children: [
                TextSpan(
                  text: action,
                  style: AppTextStyles.secondary(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Full-width "Google से जारी रखें" / "WhatsApp से जारी रखें" style button.
class SocialButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final Color background;
  final Color foreground;
  final BorderSide? border;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.label,
    required this.leading,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.border,
  });

  factory SocialButton.google({required VoidCallback? onPressed}) =>
      SocialButton(
        label: 'Google से जारी रखें',
        leading: const Text(
          'G',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4285F4),
          ),
        ),
        background: Colors.white,
        foreground: AppColors.textPrimary,
        border: const BorderSide(color: AppColors.border),
        onPressed: onPressed,
      );

  factory SocialButton.whatsapp({required VoidCallback? onPressed}) =>
      SocialButton(
        label: 'WhatsApp से जारी रखें',
        leading: const Icon(AppIcons.whatsapp, size: 20, color: Colors.white),
        background: AppColors.whatsapp,
        foreground: Colors.white,
        onPressed: onPressed,
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, child: Center(child: leading)),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
