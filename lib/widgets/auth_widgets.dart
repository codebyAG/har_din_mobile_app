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
        fillColor: Colors.white.withValues(alpha: 0.92),
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
