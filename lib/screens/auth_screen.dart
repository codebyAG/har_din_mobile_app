import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/utils/phone_utils.dart';
import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/name_prompt.dart';
import '../widgets/primary_button.dart';
import 'otp_screen.dart';
import 'root_shell.dart';

/// How the auth flow was left. Backing out pops `null`.
enum AuthResult { signedIn, skipped }

/// The one entry point for login *and* sign up: the user types only a
/// mobile number and is taken to the OTP screen. There is no separate
/// signup call — the backend creates the account on the first successful
/// verification, and `is_new_user` decides whether to ask for a name.
///
/// Pops [AuthResult.signedIn] once the user is in, [AuthResult.skipped]
/// via the optional skip link, or `null` when backing out — the app works
/// fine as a guest.
class AuthScreen extends StatefulWidget {
  /// Show a "continue without login" link (used right after onboarding).
  final bool allowSkip;

  /// This screen is the app's only route (e.g. right after logout): when
  /// the user finishes, replace everything with the main app instead of
  /// popping, and back leaves the app.
  final bool isRoot;

  const AuthScreen({super.key, this.allowSkip = false, this.isRoot = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final _phoneRe = RegExp(r'^[6-9]\d{9}$');

  final _phoneController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();

  void _finish(AuthResult result) {
    if (widget.isRoot) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _sendOtp() async {
    if (!_phoneRe.hasMatch(_phone)) {
      setState(() => _error = '10 अंकों का सही मोबाइल नंबर डालें।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    final OtpSent sent;
    try {
      sent = await auth.sendOtp(_phone);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    // Non-null result = the OTP was verified and the user is signed in.
    final isNewUser = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            OtpScreen(phone: _phone, initialRetryAfterSec: sent.retryAfterSec),
      ),
    );
    if (!mounted || isNewUser == null) return;

    if (isNewUser) {
      // First run: ask for a name. Dismissing it is fine — the profile
      // stays incomplete and Profile asks again later.
      await showNamePrompt(
        context,
        onSave: (name) async {
          try {
            await auth.saveName(name);
            return null;
          } on AuthFailure catch (failure) {
            return failure.message;
          }
        },
      );
      if (!mounted) return;
    }
    // Tell the server which language this user picked (silent, best effort).
    unawaited(auth.syncLanguage(context.read<AppLanguageController>().code));
    _finish(AuthResult.signedIn);
  }

  @override
  Widget build(BuildContext context) {
    final page = _buildPage();
    if (!widget.isRoot) return page;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: page,
    );
  }

  Widget _buildPage() {
    return AuthPage(
      title: 'Login / Sign Up करें',
      subtitle: 'अपना मोबाइल नंबर डालें, बाकी हम संभाल लेंगे',
      children: [
        AuthField(
          controller: _phoneController,
          hint: 'मोबाइल नंबर लिखें',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          // Pasted "+91 98765-43210" / "09876543210" is cleaned, not blocked.
          inputFormatters: const [IndianPhoneFormatter()],
          // +91 is drawn, not typed — the server applies the country code.
          prefix: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('+91', style: AppTextStyles.body()),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: AppTextStyles.secondary(color: AppColors.like)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: _busy ? 'कृपया रुकें…' : 'OTP भेजें',
          icon: _busy ? null : Icons.arrow_forward,
          onPressed: _busy ? null : _sendOtp,
        ),
        if (widget.allowSkip) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => _finish(AuthResult.skipped),
              style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
              child: Text(
                'अभी नहीं, बिना लॉगिन आगे बढ़ें',
                style: AppTextStyles.secondary(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
