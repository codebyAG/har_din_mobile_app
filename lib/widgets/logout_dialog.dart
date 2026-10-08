import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/auth_controller.dart';
import '../screens/auth_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: AppTextStyles.sectionHeading()),
      content: Text(body, style: AppTextStyles.body()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'रद्द करें',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.like),
          child: Text(confirmLabel, style: AppTextStyles.button()),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Clears the back stack and shows the login screen as the app's only
/// route; finishing it (or skipping) lands on a fresh Home.
void _goToLogin(NavigatorState navigator, ScaffoldMessengerState messenger) {
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const AuthScreen(allowSkip: true, isRoot: true),
    ),
    (_) => false,
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('आप लॉगआउट हो गए हैं')));
}

/// Asks "लॉगआउट करें?" and, on yes, signs this device out and sends the
/// user back to the login screen (clearing the back stack). Returns true
/// if they were logged out.
Future<bool> logoutWithConfirm(BuildContext context) async {
  // Grab these before any await — the calling screen is about to be
  // removed from the tree.
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final auth = context.read<AuthController>();

  final confirmed = await _confirm(
    context,
    title: 'लॉगआउट करें?',
    body:
        'क्या आप सच में लॉगआउट करना चाहते हैं? आप कभी भी अपने मोबाइल नंबर '
        'से दोबारा लॉगिन कर सकते हैं।',
    confirmLabel: 'लॉगआउट',
  );
  if (!confirmed) return false;

  await auth.logout();
  _goToLogin(navigator, messenger);
  return true;
}

/// "सभी डिवाइस से लॉगआउट": signs out every phone this number is logged
/// in on (`DELETE /v1/auth/me`). Unlike a normal logout this needs the
/// server, so on failure the user stays signed in and is told why.
Future<bool> logoutEverywhereWithConfirm(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final auth = context.read<AuthController>();

  final confirmed = await _confirm(
    context,
    title: 'सभी डिवाइस से लॉगआउट करें?',
    body:
        'इस नंबर से लॉगिन किए हुए सभी फ़ोन लॉगआउट हो जाएंगे। आप कभी भी '
        'दोबारा लॉगिन कर सकते हैं।',
    confirmLabel: 'सभी से लॉगआउट',
  );
  if (!confirmed) return false;

  try {
    await auth.logoutEverywhere();
  } on AuthFailure catch (failure) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
    return false;
  }
  _goToLogin(navigator, messenger);
  return true;
}
