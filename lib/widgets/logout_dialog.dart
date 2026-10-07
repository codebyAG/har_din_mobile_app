import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/providers/auth_controller.dart';
import '../screens/auth_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Asks "लॉगआउट करें?" and, on yes, signs the user out and sends them back
/// to the login screen (clearing the back stack). Returns true if they
/// were logged out.
Future<bool> logoutWithConfirm(BuildContext context) async {
  // Grab these before any await — the calling screen is about to be
  // removed from the tree.
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final auth = context.read<AuthController>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('लॉगआउट करें?', style: AppTextStyles.sectionHeading()),
      content: Text(
        'क्या आप सच में लॉगआउट करना चाहते हैं? आप कभी भी अपने मोबाइल नंबर '
        'से दोबारा लॉगिन कर सकते हैं।',
        style: AppTextStyles.body(),
      ),
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
          child: Text('लॉगआउट', style: AppTextStyles.button()),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  await auth.logout();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const AuthScreen(allowSkip: true, isRoot: true),
    ),
    (_) => false,
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('आप लॉगआउट हो गए हैं')));
  return true;
}
