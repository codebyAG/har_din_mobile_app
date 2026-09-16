import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/event_queue.dart';
import '../presentation/providers/app_language_controller.dart';
import '../presentation/providers/content_view_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_drawer.dart';
import 'festivals_screen.dart';
import 'home_screen.dart';
import 'language_select_screen.dart';
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
  bool _languageMissingHandled = false;

  final _screens = const [
    HomeScreen(),
    FestivalsScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  List<_TabSpec> _tabs(ContentViewModel viewModel) => [
        (icon: AppIcons.home, activeIcon: AppIcons.homeSolid, label: viewModel.t('nav.home')),
        (
          icon: AppIcons.festivals,
          activeIcon: AppIcons.festivalsSolid,
          label: viewModel.t('nav.festivals'),
        ),
        (icon: AppIcons.saved, activeIcon: AppIcons.savedSolid, label: viewModel.t('nav.creations')),
        (
          icon: AppIcons.profile,
          activeIcon: AppIcons.profileSolid,
          label: viewModel.t('nav.profile'),
        ),
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
      // "Next app open" flush trigger (§8, APP-CHANGES-01 §4) — whatever
      // the last session left queued goes out now, not just at 20 events.
      EventQueue.instance.flush();
    });
  }

  @override
  Widget build(BuildContext context) {
    // §10 — a 404 on version/content means the selected language no
    // longer exists server-side. Re-prompt for language choice instead
    // of silently showing stale/empty content forever.
    final languageMissing = context.watch<ContentViewModel>().languageMissing;
    if (languageMissing && !_languageMissingHandled) {
      _languageMissingHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LanguageSelectScreen()),
        );
      });
    }

    return Scaffold(
      extendBody: true,
      drawer: AppDrawer(onSelectTab: (i) => setState(() => _index = i)),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _NavBar(
        selectedIndex: _index,
        tabs: _tabs(context.watch<ContentViewModel>()),
        onTabTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

typedef _TabSpec = ({IconData icon, IconData activeIcon, String label});

/// A floating pill dock, not an edge-to-edge bar — the selected tab
/// expands into a gradient capsule with its label; the rest stay as
/// plain icons. Reads as a single moving piece rather than four static
/// buttons with an underline.
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

    return Padding(
      // Clears the system inset (gesture bar / home indicator) *and*
      // adds a visible gap on top of it — otherwise the pill just sits
      // flush against the safe-area edge instead of reading as floating.
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        // Not Expanded/equal-width — an equal quarter-share is too
        // narrow to fit the longest label ("मेरी क्रिएशन्स") without
        // truncating it. Each tab sizes to its own content instead
        // (icon-only when idle, icon+full label when selected), and
        // spaceEvenly distributes whatever room is left as gaps.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _NavTab(
                tab: tabs[i],
                selected: selectedIndex == i,
                onTap: () => onTabTap(i),
              ),
          ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 19,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.centerLeft,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextStyles.bottomNav(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
                          ),
                        )
                      : const SizedBox(height: 19),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
