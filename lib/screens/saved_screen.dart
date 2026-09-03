import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('सेव किए गए', style: AppTextStyles.screenTitle()),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.lightAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'कोई सेव किया हुआ स्टेटस नहीं',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardTitle(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'पसंदीदा स्टेटस यहाँ दिखेंगे — दिल के निशान पर टैप करके सेव करें।',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondary(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
