import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Full-width "Premium चालू करें" button with a trust line underneath.
class PremiumCTA extends StatelessWidget {
  final VoidCallback onPressed;

  const PremiumCTA({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: 'Premium चालू करें',
            excludeSemantics: true,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      '👑 Premium चालू करें',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.button().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '🔒 सुरक्षित भुगतान  •  कभी भी बंद कर सकते हैं',
          textAlign: TextAlign.center,
          style: AppTextStyles.secondary().copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
