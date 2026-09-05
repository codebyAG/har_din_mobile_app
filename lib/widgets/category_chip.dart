import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Image.asset(
              'assets/categories/${category.id}.png',
              fit: BoxFit.contain,
              color: selected ? Colors.white : null,
              errorBuilder: (context, error, stackTrace) => Icon(
                category.icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category.label,
            style: AppTextStyles.secondary(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
