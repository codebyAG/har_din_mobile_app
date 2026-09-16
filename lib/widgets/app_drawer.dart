import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../screens/settings_screen.dart';
import 'festive_glow.dart';

/// Real navigation drawer for the app — every item does something.
class AppDrawer extends StatelessWidget {
  final ValueChanged<int> onSelectTab;

  const AppDrawer({super.key, required this.onSelectTab});

  void _goToTab(BuildContext context, int index) {
    Navigator.of(context).pop();
    onSelectTab(index);
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ContentViewModel>().t;
    return Drawer(
      backgroundColor: AppColors.background,
      width: 288,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                0,
              ),
              children: [
                const _SectionLabel('मुख्य'),
                const SizedBox(height: AppSpacing.sm),
                _DrawerTile(
                  icon: AppIcons.home,
                  gradient: const [Color(0xFFFF8A3D), AppColors.primary],
                  label: t('nav.home'),
                  onTap: () => _goToTab(context, 0),
                ),
                _DrawerTile(
                  icon: AppIcons.festivals,
                  gradient: const [AppColors.secondary, AppColors.primary],
                  label: t('nav.festivals'),
                  onTap: () => _goToTab(context, 1),
                ),
                _DrawerTile(
                  icon: AppIcons.saved,
                  gradient: const [Color(0xFFFF7A70), AppColors.like],
                  label: t('nav.creations'),
                  onTap: () => _goToTab(context, 2),
                ),
                _DrawerTile(
                  icon: AppIcons.profile,
                  gradient: const [Color(0xFF6FA8E8), Color(0xFF3D6FC2)],
                  label: t('nav.profile'),
                  onTap: () => _goToTab(context, 3),
                ),
                // Feed is unreachable in v1 — no posts, no comments, no users (§5).
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('और'),
                const SizedBox(height: AppSpacing.sm),
                _DrawerTile(
                  icon: AppIcons.settingsGear,
                  gradient: const [Color(0xFF8C7C6C), AppColors.textSecondary],
                  label: 'सेटिंग',
                  onTap: () => _push(context, const SettingsScreen()),
                ),
                _DrawerTile(
                  icon: AppIcons.share,
                  gradient: const [Color(0xFF4FC077), AppColors.success],
                  label: 'ऐप शेयर करें',
                  onTap: () {
                    Navigator.of(context).pop();
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'हर दिन ऐप डाउनलोड करो — हर त्योहार के लिए खूबसूरत स्टेटस, '
                            'कोट्स और शुभकामनाएं। Har Din, Kuch Share Karo!',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                const Icon(AppIcons.celebration, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text('हर दिन · v1.0.0', style: AppTextStyles.secondary()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary, AppColors.primaryDark],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                top: -30,
                right: -40,
                child: FestiveGlow(size: 150, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/har_din_app_logo_transparent.png'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('हर दिन', style: AppTextStyles.screenTitle(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    'Har Din, Kuch Share Karo',
                    style: AppTextStyles.secondary(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
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
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.last.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 15, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w500),
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
