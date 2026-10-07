import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/primary_button.dart';

/// Second step of auth: the 6-digit OTP texted to [phone]. Pops `true`
/// once the OTP is verified and the session is stored.
class OtpScreen extends StatefulWidget {
  final String phone;

  /// From the backend's `exists` flag — only changes the wording
  /// ("Sign Up" vs "Login"); the server does the real work.
  final bool isNewUser;

  const OtpScreen({super.key, required this.phone, required this.isNewUser});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (!AuthController.offlineDemoAuth && otp.length != 6) {
      setState(() => _error = '6 अंकों का OTP डालें।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<AuthController>().verifyOtp(
      phone: widget.phone,
      otp: otp,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    _otpController.clear(); // wrong OTP — start the boxes over
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await context.read<AuthController>().sendOtp(widget.phone);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.error;
    });
    if (result.error == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('OTP दोबारा भेज दिया गया')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'OTP डालें',
      subtitle: '+91 ${widget.phone} पर भेजा गया 6 अंकों का कोड डालें',
      children: [
        OtpInput(
          controller: _otpController,
          enabled: !_busy,
          onCompleted: _verify,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _busy ? null : _resend,
            style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
            child: Text(
              'OTP दोबारा भेजें',
              style: AppTextStyles.secondary(
                color: AppColors.primary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: AppTextStyles.secondary(color: AppColors.like)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: _busy
              ? 'कृपया रुकें…'
              : (widget.isNewUser ? 'Sign Up करें' : 'Login करें'),
          icon: _busy ? null : Icons.arrow_forward,
          onPressed: _busy ? null : _verify,
        ),
      ],
    );
  }
}
