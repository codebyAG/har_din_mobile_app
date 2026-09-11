import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(
            onSettings: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              children: [
                _ProfileMenuTile(
                  icon: AppIcons.grid,
                  label: 'मेरे पोस्ट्स',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedScreen()),
                  ),
                ),
                _ProfileMenuTile(
                  icon: AppIcons.bookmarkOutline,
                  label: 'सेव्ड',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedScreen()),
                  ),
                ),
                _ProfileMenuTile(
                  icon: AppIcons.heartOutline,
                  label: 'मेरी पसंद',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedScreen()),
                  ),
                ),
                // "खोजे गए लोग" and logout removed — no accounts in v1 (§5).
                _ProfileMenuTile(
                  icon: AppIcons.settingsGear,
                  label: 'सेटिंग',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onSettings;

  const _ProfileHeader({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xxl,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(AppIcons.settingsGear, color: Colors.white),
                ),
              ],
            ),
            const CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child: Icon(AppIcons.account, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            // No fake name/handle — there are no accounts in v1 (§5),
            // so there is no real identity to show here.
            Text(
              'हर दिन',
              style: AppTextStyles.screenTitle(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Har Din, Kuch Share Karo',
              style: AppTextStyles.secondary(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
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
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTextStyles.body())),
            const Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
