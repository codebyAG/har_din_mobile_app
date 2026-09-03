import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('सेटिंग')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _SettingsTile(icon: Icons.person_outline, label: 'अकाउंट सेटिंग'),
            _SettingsTile(icon: Icons.lock_outline, label: 'प्राइवेसी सेटिंग'),
            _SettingsTile(icon: Icons.notifications_none, label: 'नोटिफिकेशन'),
            _SettingsTile(icon: Icons.language, label: 'भाषा', value: 'हिंदी'),
            _SettingsTile(icon: Icons.dark_mode_outlined, label: 'थीम', value: 'लाइट'),
            _SettingsTile(icon: Icons.help_outline, label: 'सहायता और सपोर्ट'),
            _SettingsTile(icon: Icons.info_outline, label: 'ऐप के बारे में'),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('लॉग आउट किया गया')),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'लॉग आउट',
                  style: AppTextStyles.body(color: AppColors.like)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _SettingsTile({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.body())),
          if (value != null) ...[
            Text(value!, style: AppTextStyles.secondary()),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
