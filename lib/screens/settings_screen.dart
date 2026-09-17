import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/image_cache_service.dart';
import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _pickOption(String title, List<String> options, String current,
      ValueChanged<String> onPicked) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(title, style: AppTextStyles.cardTitle()),
            ),
            for (final option in options)
              ListTile(
                title: Text(option, style: AppTextStyles.body()),
                trailing: option == current
                    ? const Icon(AppIcons.free, color: AppColors.primary, size: 18)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ContentViewModel>().t;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(AppIcons.settingsGear, size: 16, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('सेटिंग', style: AppTextStyles.screenTitle()),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            const _SectionLabel('अकाउंट'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsTile(
              icon: AppIcons.account,
              gradient: const [Color(0xFFFF8A3D), AppColors.primary],
              label: 'अकाउंट सेटिंग',
              onTap: () => _snack(t('settings.account_soon')),
            ),
            _SettingsTile(
              icon: AppIcons.privacy,
              gradient: const [Color(0xFF6FA8E8), Color(0xFF3D6FC2)],
              label: 'प्राइवेसी सेटिंग',
              onTap: () => _snack(t('settings.privacy_soon')),
            ),
            _SettingsTile(
              icon: AppIcons.bell,
              gradient: const [Color(0xFFFFC96B), AppColors.secondary],
              label: 'नोटिफिकेशन',
              onTap: () => _snack(t('settings.notifications_soon')),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionLabel('प्राथमिकताएं'),
            const SizedBox(height: AppSpacing.sm),
            Consumer<AppLanguageController>(
              builder: (context, languageController, _) {
                // Real `languages[]` once content has loaded; the fixed
                // API set (§3) as a fallback before that (or offline).
                final payload = context.watch<ContentViewModel>().payload;
                final options = payload != null && payload.languages.isNotEmpty
                    ? {for (final l in payload.languages) l.label: l.code}
                    : const {'हिन्दी': 'hi', 'English': 'en', 'मराठी': 'mr'};
                final currentLabel = options.entries
                    .firstWhere(
                      (e) => e.value == languageController.code,
                      orElse: () => options.entries.first,
                    )
                    .key;
                return _SettingsTile(
                  icon: AppIcons.language,
                  gradient: const [Color(0xFF4FC077), AppColors.success],
                  label: 'भाषा',
                  value: currentLabel,
                  onTap: () => _pickOption(
                    'भाषा चुनें',
                    options.keys.toList(),
                    currentLabel,
                    (label) async {
                      final code = options[label]!;
                      await languageController.setLanguageCode(code);
                      if (!context.mounted) return;
                      await context
                          .read<ContentViewModel>()
                          .load(code, forceLanguageSwitch: true);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionLabel('सहायता'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsTile(
              icon: AppIcons.help,
              gradient: const [Color(0xFFFF7A70), AppColors.like],
              label: 'सहायता और सपोर्ट',
              onTap: () => _snack(t('settings.help_soon')),
            ),
            _SettingsTile(
              icon: AppIcons.about,
              gradient: const [Color(0xFFB09B8C), Color(0xFF6E6153)],
              label: 'ऐप के बारे में',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'हर दिन',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Har Din, Kuch Share Karo',
              ),
            ),
            _SettingsTile(
              icon: AppIcons.download,
              gradient: const [Color(0xFF6FA8E8), Color(0xFF3D6FC2)],
              label: 'कैश खाली करें',
              onTap: () async {
                await ImageCacheService.instance.emptyCache();
                if (!context.mounted) return;
                _snack('कैश खाली कर दिया गया');
              },
            ),
            // Logout removed — no accounts in v1 (§5).
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: AppTextStyles.secondary().copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.last.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                if (value != null) ...[
                  Text(value!, style: AppTextStyles.secondary()),
                  const SizedBox(width: AppSpacing.xs),
                ],
                const Icon(AppIcons.chevronRight, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
