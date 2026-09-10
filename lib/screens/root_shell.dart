import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/event_queue.dart';
import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_drawer.dart';
import '../widgets/glass_container.dart';
import 'festivals_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

/// Bottom nav is exactly four tabs (§5) — होम · त्योहार · मेरी क्रिएशन्स ·
/// प्रोफाइल. The centre "create" button from the pre-integration UI is
/// gone: Create Post has no upload endpoint, no accounts, no moderation
/// in v1, so it's unreachable rather than removed from the codebase.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  bool _loadTriggered = false;

  final _screens = const [
    HomeScreen(),
    FestivalsScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  static const _tabs = [
    (icon: AppIcons.home, activeIcon: AppIcons.homeSolid, label: 'होम'),
    (icon: AppIcons.festivals, activeIcon: AppIcons.festivalsSolid, label: 'त्योहार'),
    (icon: AppIcons.saved, activeIcon: AppIcons.savedSolid, label: 'मेरी क्रिएशन्स'),
    (icon: AppIcons.profile, activeIcon: AppIcons.profileSolid, label: 'प्रोफाइल'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fires once per RootShell lifetime, not per tab switch (§4) — this
    // is the one place `ContentViewModel.load` is called for a normal
    // app open.
    if (_loadTriggered) return;
    _loadTriggered = true;
    final code = context.read<AppLanguageController>().code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContentViewModel>().load(code);
      EventQueue.instance.record(HarDinEventType.appOpen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: AppDrawer(onSelectTab: (i) => setState(() => _index = i)),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _NavBar(
        selectedIndex: _index,
        tabs: _tabs,
        onTabTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

typedef _TabSpec = ({IconData icon, IconData activeIcon, String label});

class _NavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onTabTap;

  const _NavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const barContentHeight = 64.0;
    final barHeight = barContentHeight + bottomInset;

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        tint: AppColors.card,
        tintOpacity: 0.72,
        border: const Border(
          top: BorderSide(color: Colors.white, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                _NavTab(tab: tabs[i], selected: selectedIndex == i, onTap: () => onTabTap(i)),
            ],
          ),
        ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
