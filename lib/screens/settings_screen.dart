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
  String _theme = 'लाइट';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('सेटिंग')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _SettingsTile(
              icon: AppIcons.account,
              label: 'अकाउंट सेटिंग',
              onTap: () => _snack('अकाउंट सेटिंग जल्द आ रही है'),
            ),
            _SettingsTile(
              icon: AppIcons.privacy,
              label: 'प्राइवेसी सेटिंग',
              onTap: () => _snack('प्राइवेसी सेटिंग जल्द आ रही है'),
            ),
            _SettingsTile(
              icon: AppIcons.bell,
              label: 'नोटिफिकेशन',
              onTap: () => _snack('नोटिफिकेशन सेटिंग जल्द आ रही है'),
            ),
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
            _SettingsTile(
              icon: AppIcons.theme,
              label: 'थीम',
              value: _theme,
              onTap: () => _pickOption(
                'थीम चुनें',
                ['लाइट', 'डार्क', 'सिस्टम'],
                _theme,
                (v) => setState(() => _theme = v),
              ),
            ),
            _SettingsTile(
              icon: AppIcons.help,
              label: 'सहायता और सपोर्ट',
              onTap: () => _snack('सहायता जल्द आ रही है'),
            ),
            _SettingsTile(
              icon: AppIcons.about,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTextStyles.body())),
            if (value != null) ...[
              Text(value!, style: AppTextStyles.secondary()),
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(AppIcons.chevronRight, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
