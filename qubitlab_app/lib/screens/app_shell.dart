import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/saved_circuits_provider.dart';
import '../theme/app_theme.dart';
import 'arena_screen.dart';
import 'guided_labs_screen.dart';
import 'home_screen.dart';
import 'lab_screen.dart';
import 'learn_screen.dart';

/// Lets any screen switch tabs (e.g. Home -> Lab when opening a saved circuit).
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _pages = <Widget>[
    HomeScreen(),
    LearnScreen(),
    GuidedLabsScreen(),
    LabScreen(),
    ArenaScreen(),
  ];

  @override
  void initState() {
    super.initState();
    shellTab.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AuthProvider>().userId;
      if (id != null) context.read<SavedCircuitsProvider>().load(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: _PillNav(index: index, onTap: (i) => shellTab.value = i),
      ),
    );
  }
}

class _PillNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _PillNav({required this.index, required this.onTap});

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Home'),
    (Icons.menu_book_rounded, 'Learn'),
    (Icons.explore_rounded, 'Guided'),
    (Icons.science_rounded, 'Lab'),
    (Icons.emoji_events_rounded, 'Arena'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _items.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(horizontal: i == index ? 14 : 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(_items[i].$1,
                          size: 22, color: i == index ? Colors.white : AppColors.muted),
                      if (i == index) ...[
                        const SizedBox(width: 8),
                        Text(_items[i].$2,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
