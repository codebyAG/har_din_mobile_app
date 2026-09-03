import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FreeBadge extends StatelessWidget {
  const FreeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text(
        'FREE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
