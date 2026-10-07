import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/primary_button.dart';

/// How the login screen was left. Backing out pops `null`.
enum LoginResult { signedIn, skipped }

/// Login and sign up on one route, so "pop with a result" stays simple.
/// The footer link flips between the two modes in place.
///
/// Pops [LoginResult.signedIn] once the user is signed in, or
/// [LoginResult.skipped] via the optional skip link; backing out pops
/// `null` — the app works fine as a guest.
class LoginScreen extends StatefulWidget {
  /// Open on the sign-up form instead of login.
  final bool startAsSignUp;

  /// Show a "continue without login" link (used right after onboarding).
  final bool allowSkip;

  const LoginScreen({
    super.key,
    this.startAsSignUp = false,
    this.allowSkip = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _signUp = widget.startAsSignUp;
  bool _showPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static final _phoneRe = RegExp(r'^[6-9]\d{9}$');

  void _switchMode() {
    if (_busy) return;
    setState(() {
      _signUp = !_signUp;
      _error = null;
    });
  }

  /// Returns a Hindi message for the first invalid field, or null.
  String? _validate() {
    if (AuthController.offlineDemoAuth) return null; // accept anything for now
    if (_signUp && _nameController.text.trim().length < 2) {
      return 'अपना नाम लिखें।';
    }
    if (!_phoneRe.hasMatch(_phoneController.text.trim())) {
      return '10 अंकों का सही मोबाइल नंबर डालें।';
    }
    final password = _passwordController.text;
    if (_signUp && password.length < 6) {
      return 'पासवर्ड कम से कम 6 अक्षर का रखें।';
    }
    if (!_signUp && password.isEmpty) return 'पासवर्ड डालें।';
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final error = _signUp
        ? await auth.signUp(
            name: _nameController.text.trim(),
            phone: phone,
            password: password,
          )
        : await auth.login(phone: phone, password: password);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(LoginResult.signedIn);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('यह विकल्प जल्द आ रहा है')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    Center(
                      child: Image.asset(AuthBackground.logoAsset, width: 190),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Har Din, Kuch Share Karo ❤️',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondary(
                        color: AppColors.textPrimary,
                      ).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _signUp ? 'Sign Up करें' : 'Login करें',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle().copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _signUp
                          ? 'नया अकाउंट बनाएं और हरदिन से जुड़ें'
                          : 'अपने अकाउंट में लॉगिन करें',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondary(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_signUp) ...[
                      AuthField(
                        controller: _nameController,
                        hint: 'अपना नाम लिखें',
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AuthField(
                      controller: _phoneController,
                      hint: 'मोबाइल नंबर लिखें',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthField(
                      controller: _passwordController,
                      hint: _signUp
                          ? 'पासवर्ड बनाएं (कम से कम 6 अक्षर)'
                          : 'पासवर्ड लिखें',
                      icon: Icons.lock_outline,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        tooltip: _showPassword
                            ? 'पासवर्ड छिपाएं'
                            : 'पासवर्ड दिखाएं',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    if (!_signUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 44),
                          ),
                          child: Text(
                            'पासवर्ड भूल गए?',
                            style: AppTextStyles.secondary(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: AppTextStyles.secondary(color: AppColors.like),
                      ),
                    ],
                    SizedBox(height: _signUp ? AppSpacing.xl : AppSpacing.sm),
                    PrimaryButton(
                      label: _busy
                          ? 'कृपया रुकें…'
                          : _signUp
                          ? 'Sign Up करें'
                          : 'Login करें',
                      icon: _busy ? null : Icons.arrow_forward,
                      onPressed: _busy ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthFooterLink(
                      prompt: _signUp
                          ? 'पहले से अकाउंट है?'
                          : 'अभी अकाउंट नहीं है?',
                      action: _signUp ? 'Login करें' : 'Sign Up करें',
                      onTap: _switchMode,
                    ),
                    if (widget.allowSkip)
                      Center(
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pop(LoginResult.skipped),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 44),
                          ),
                          child: Text(
                            'अभी नहीं, बिना लॉगिन आगे बढ़ें',
                            style: AppTextStyles.secondary(),
                          ),
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
