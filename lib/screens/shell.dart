import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'umrah/umrah_screen.dart';
import 'map/map_screen.dart';
import 'lost/lost_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        open: (x) {
          setState(() {
            i = x;
          });
        },
      ),
      const UmrahScreen(),
      const MapScreen(),
      const LostScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: i,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (x) {
          setState(() {
            i = x;
          });
        },
        indicatorColor: AppColors.softGreen,
        destinations: const [
          NavigationDestination(
            icon: Text(
              '🏠',
              style: TextStyle(fontSize: 22),
            ),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Text(
              '🕋',
              style: TextStyle(fontSize: 22),
            ),
            label: 'العمرة',
          ),
          NavigationDestination(
            icon: Text(
              '🗺️',
              style: TextStyle(fontSize: 22),
            ),
            label: 'الخريطة',
          ),
          NavigationDestination(
            icon: Text(
              '🆘',
              style: TextStyle(fontSize: 22),
            ),
            label: 'تهت؟',
          ),
        ],
      ),
    );
  }
}