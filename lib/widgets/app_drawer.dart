import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../screens/feed_screen.dart';
import '../screens/settings_screen.dart';

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
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Image.asset('assets/har_din_app_logo_transparent.png', height: 40),
                  const SizedBox(width: AppSpacing.sm),
                  Text('हर दिन', style: AppTextStyles.screenTitle()),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            _DrawerTile(
              icon: AppIcons.home,
              label: 'होम',
              onTap: () => _goToTab(context, 0),
            ),
            _DrawerTile(
              icon: AppIcons.festivals,
              label: 'त्योहार',
              onTap: () => _goToTab(context, 1),
            ),
            _DrawerTile(
              icon: AppIcons.saved,
              label: 'मेरी क्रिएशन्स',
              onTap: () => _goToTab(context, 2),
            ),
            _DrawerTile(
              icon: AppIcons.profile,
              label: 'प्रोफाइल',
              onTap: () => _goToTab(context, 3),
            ),
            _DrawerTile(
              icon: AppIcons.quote,
              label: 'फ़ीड',
              onTap: () => _push(context, const FeedScreen()),
            ),
            const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
            _DrawerTile(
              icon: AppIcons.settingsGear,
              label: 'सेटिंग',
              onTap: () => _push(context, const SettingsScreen()),
            ),
            _DrawerTile(
              icon: AppIcons.share,
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'v1.0.0',
                style: AppTextStyles.secondary(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.body()),
      onTap: onTap,
    );
  }
}
