import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/primary_button.dart';

/// Second step of auth: the 6-digit OTP texted to [phone].
///
/// Pops `is_new_user` (true / false) once the code is verified and the
/// session is stored; backing out pops `null`.
class OtpScreen extends StatefulWidget {
  final String phone;

  /// `retry_after_sec` from the send call — drives the Resend countdown.
  /// Never a hardcoded 30: the cooldown is server configuration.
  final int initialRetryAfterSec;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.initialRetryAfterSec,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _ticker;

  bool _busy = false;
  String? _error;

  /// Seconds until Resend is accepted again (0 = available now).
  int _cooldown = 0;

  /// Seconds the number is locked after too many wrong codes. While set,
  /// there is no OTP entry and no Resend — only the countdown.
  int _lockSeconds = 0;

  /// Voice is offered once a text resend has already been used: on a weak
  /// signal it is the biggest recovery of abandoned sign-ups.
  bool _textResent = false;

  @override
  void initState() {
    super.initState();
    _cooldown = widget.initialRetryAfterSec;
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_cooldown > 0) _cooldown--;
        if (_lockSeconds > 0) _lockSeconds--;
      });
      if (_cooldown == 0 && _lockSeconds == 0) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  bool get _locked => _lockSeconds > 0;

  String _fmt(int seconds) {
    if (seconds < 60) return '$seconds सेकंड';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '$m मिनट' : '$m मिनट $s सेकंड';
  }

  Future<void> _verify() async {
    if (_busy || _locked) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = '6 अंकों का OTP डालें।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final isNewUser = await context.read<AuthController>().verifyOtp(
        widget.phone,
        otp,
      );
      if (!mounted) return;
      Navigator.of(context).pop(isNewUser);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
        switch (failure.kind) {
          case AuthFailureKind.wrongCode:
            _otpController.clear(); // start the boxes over
          case AuthFailureKind.rateLimited:
            _otpController.clear();
            _lockSeconds = failure.retryAfterSec ?? 60;
            _startTicker();
          // 503 / network: keep the digits — the code is probably right,
          // so the user must not have to retype it (or think it was wrong).
          default:
            break;
        }
      });
    }
  }

  Future<void> _resend(OtpChannel channel) async {
    if (_busy || _cooldown > 0 || _locked) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await context.read<AuthController>().resendOtp(
        widget.phone,
        channel: channel,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _cooldown = sent.retryAfterSec;
        if (channel == OtpChannel.text) _textResent = true;
      });
      _startTicker();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              channel == OtpChannel.voice
                  ? 'आपको कॉल पर OTP बताया जाएगा'
                  : 'OTP दोबारा भेज दिया गया',
            ),
          ),
        );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
        if (failure.kind == AuthFailureKind.rateLimited) {
          _cooldown = failure.retryAfterSec ?? _cooldown;
          _startTicker();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'OTP डालें',
      subtitle: '+91 ${widget.phone} पर भेजा गया 6 अंकों का कोड डालें',
      children: [
        if (_locked)
          _LockedNotice(
            text:
                'बहुत ज़्यादा गलत कोड। ${_fmt(_lockSeconds)} बाद फिर कोशिश करें।',
          )
        else ...[
          OtpInput(
            controller: _otpController,
            enabled: !_busy,
            onCompleted: _verify,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy || _cooldown > 0
                  ? null
                  : () => _resend(OtpChannel.text),
              style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
              child: Text(
                _cooldown > 0
                    ? '$_cooldown सेकंड में दोबारा भेजें'
                    : 'OTP दोबारा भेजें',
                style: AppTextStyles.secondary(
                  color: _cooldown > 0
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_textResent)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy || _cooldown > 0
                    ? null
                    : () => _resend(OtpChannel.voice),
                style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: Text(
                  'कॉल पर OTP सुनें',
                  style: AppTextStyles.secondary(
                    color: _cooldown > 0
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
        if (_error != null && !_locked) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: AppTextStyles.secondary(color: AppColors.like)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: _busy ? 'कृपया रुकें…' : 'वेरीफाई करें',
          icon: _busy ? null : Icons.arrow_forward,
          onPressed: _busy || _locked ? null : _verify,
        ),
      ],
    );
  }
}

class _LockedNotice extends StatelessWidget {
  final String text;

  const _LockedNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.like.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_outlined, color: AppColors.like),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.secondary(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
