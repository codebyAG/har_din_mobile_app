import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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

  void _onTap(int tappedNavIndex) {
    if (tappedNavIndex == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );
      return;
    }
    final pageIndex = tappedNavIndex < 2 ? tappedNavIndex : tappedNavIndex - 1;
    setState(() => _index = pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = _index < 2 ? _index : _index + 1;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'होम',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'फेस्टिवल',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
            label: 'पोस्ट करें',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'सेव',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'प्रोफाइल',
          ),
        ],
      ),
    );
  }
}
