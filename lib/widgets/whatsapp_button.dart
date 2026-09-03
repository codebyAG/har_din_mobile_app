import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class WhatsAppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const WhatsAppButton({
    super.key,
    this.label = 'WhatsApp पर शेयर करें',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whatsapp,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.button()),
          ],
        ),
      ),
    );
  }
}
