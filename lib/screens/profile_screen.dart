import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../presentation/providers/saved_designs_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festive_glow.dart';
import '../widgets/glass_container.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedDesignsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ProfileHeader(
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              Positioned(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: -38,
                child: _StatsCard(
                  downloadedCount: saved.downloaded.length,
                  favoriteCount: saved.favorites.length,
                  onTapDownloaded: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedScreen()),
                  ),
                  onTapFavorites: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 38 + AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('मेरी क्रिएशन्स'),
                const SizedBox(height: AppSpacing.sm),
                _ProfileMenuTile(
                  icon: AppIcons.download,
                  gradient: const [Color(0xFFFF8A3D), AppColors.primary],
                  label: 'डाउनलोड की गईं',
                  trailingCount: saved.downloaded.length,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedScreen()),
                  ),
                ),
                _ProfileMenuTile(
                  icon: AppIcons.heartSolid,
                  gradient: const [Color(0xFFFF7A70), AppColors.like],
                  label: 'पसंदीदा',
                  trailingCount: saved.favorites.length,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('और'),
                const SizedBox(height: AppSpacing.sm),
                _ProfileMenuTile(
                  icon: AppIcons.settingsGear,
                  gradient: const [Color(0xFF8C7C6C), AppColors.textSecondary],
                  label: 'सेटिंग',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                _ProfileMenuTile(
                  icon: AppIcons.share,
                  gradient: const [Color(0xFF4FC077), AppColors.success],
                  label: 'ऐप शेयर करें',
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text: 'हर दिन ऐप डाउनलोड करो — हर त्योहार के लिए खूबसूरत स्टेटस, '
                          'कोट्स और शुभकामनाएं। Har Din, Kuch Share Karo!',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    'हर दिन · v1.0.0',
                    style: AppTextStyles.secondary().copyWith(letterSpacing: 0.2),
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.xxxl + AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary, AppColors.primaryDark],
            stops: [0.0, 0.45, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: -40,
              right: -50,
              child: FestiveGlow(size: 220, color: Colors.white),
            ),
            const Positioned(
              bottom: 10,
              left: -60,
              child: FestiveGlow(size: 160, color: AppColors.secondary),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onSettings,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: GlassContainer(
                            borderRadius: BorderRadius.circular(100),
                            tint: Colors.white,
                            tintOpacity: 0.18,
                            blur: 12,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: Icon(AppIcons.settingsGear, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.white, AppColors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: Icon(AppIcons.account, size: 42, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // No fake name/handle — there are no accounts in v1
                  // (§5), so there is no real identity to show here.
                  Text(
                    'हर दिन',
                    style: AppTextStyles.screenTitle(color: Colors.white).copyWith(
                      fontSize: 22,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Har Din, Kuch Share Karo',
                    style: AppTextStyles.secondary(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int downloadedCount;
  final int favoriteCount;
  final VoidCallback onTapDownloaded;
  final VoidCallback onTapFavorites;

  const _StatsCard({
    required this.downloadedCount,
    required this.favoriteCount,
    required this.onTapDownloaded,
    required this.onTapFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(22),
          tint: Colors.white,
          tintOpacity: 0.86,
          blur: 20,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    icon: AppIcons.download,
                    iconColor: AppColors.primary,
                    value: downloadedCount,
                    label: 'डाउनलोड',
                    onTap: onTapDownloaded,
                  ),
                ),
                Container(width: 1, height: 34, color: AppColors.border),
                Expanded(
                  child: _StatCell(
                    icon: AppIcons.heartSolid,
                    iconColor: AppColors.like,
                    value: favoriteCount,
                    label: 'पसंदीदा',
                    onTap: onTapFavorites,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final VoidCallback onTap;

  const _StatCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(icon, size: 14, color: iconColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text('$value', style: AppTextStyles.screenTitle()),
                ],
              ),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.secondary()),
            ],
          ),
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

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final int? trailingCount;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.onTap,
    this.trailingCount,
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
                if (trailingCount != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightAccent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$trailingCount',
                      style: AppTextStyles.secondary(color: AppColors.primaryDark)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
