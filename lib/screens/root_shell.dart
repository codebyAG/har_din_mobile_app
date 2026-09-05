import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import 'create_post_screen.dart';
import 'festivals_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    FestivalsScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  static const _tabs = [
    (icon: AppIcons.home, activeIcon: AppIcons.homeSolid, label: 'होम'),
    (icon: AppIcons.festivals, activeIcon: AppIcons.festivalsSolid, label: 'फेस्टिवल'),
    (icon: AppIcons.saved, activeIcon: AppIcons.savedSolid, label: 'सेव'),
    (icon: AppIcons.profile, activeIcon: AppIcons.profileSolid, label: 'प्रोफाइल'),
  ];

  void _openCreatePost() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _PremiumNavBar(
        selectedIndex: _index,
        tabs: _tabs,
        onTabTap: (i) => setState(() => _index = i),
        onCreateTap: _openCreatePost,
      ),
    );
  }
}

typedef _TabSpec = ({IconData icon, IconData activeIcon, String label});

class _PremiumNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onTabTap;
  final VoidCallback onCreateTap;

  const _PremiumNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTabTap,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const barContentHeight = 64.0;
    final barHeight = barContentHeight + bottomInset;

    return SizedBox(
      height: barHeight + 14,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: barHeight,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavTab(tab: tabs[0], selected: selectedIndex == 0, onTap: () => onTabTap(0)),
                _NavTab(tab: tabs[1], selected: selectedIndex == 1, onTap: () => onTabTap(1)),
                const SizedBox(width: 64),
                _NavTab(tab: tabs[2], selected: selectedIndex == 2, onTap: () => onTabTap(2)),
                _NavTab(tab: tabs[3], selected: selectedIndex == 3, onTap: () => onTabTap(3)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onCreateTap,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.card, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(AppIcons.create, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _TabSpec tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? tab.activeIcon : tab.icon,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: AppTextStyles.bottomNav(
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 14 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
