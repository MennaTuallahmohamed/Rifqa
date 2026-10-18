
import 'package:flutter/material.dart';

import '../services/groups/group_service.dart';
import '../core/theme/app_colors.dart';

import 'home/home_screen.dart';
import 'assistant/lost_help_screen.dart';
import 'groups/groups_screen.dart';
import 'assistant/ask_rifqa_screen.dart';
import 'profile/rifqa_profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // The real bottom navigation indexes.
  static const int homeTab = 0;
  static const int lostTab = 1;
  static const int groupsTab = 2;
  static const int accountTab = 3;
  static const int assistantTab = 4;

  int i = homeTab;

  void _selectTab(int index) {
    if (index < homeTab || index > assistantTab) return;
    if (i == index) return;

    setState(() {
      i = index;
    });
  }

  // Handles actions coming specifically from the HomeScreen.
  // Home's legacy open(1) means Umrah guide,
  // NOT bottom tab index 1.
  void _handleHomeNavigation(int code) {
    switch (code) {
      case 0:
        _selectTab(homeTab);
        return;

      case 1:
        // We still need the actual Umrah guide screen route.
        // Do not confuse the Umrah guide with the lost-help tab.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'هنربط دليل العمرة بصفحته الأصلية بعد مراجعة مسارها.',
            ),
          ),
        );
        return;

      case 2:
        // Home's direct map navigation is handled
        // inside home_screen.dart.
        _selectTab(groupsTab);
        return;

      case 3:
        // Legacy SOS action from the old HomeScreen.
        _selectTab(lostTab);
        return;

      case 4:
        _selectTab(assistantTab);
        return;

      case -5:
        _selectTab(groupsTab);
        return;

      case -9:
        _selectTab(accountTab);
        return;

      default:
        return;
    }
  }

  Future<bool> _shareLocationWithGroup(
    double latitude,
    double longitude,
    double accuracyMeters,
  ) async {
    final groups = await GroupService.instance.myGroups().first;

    if (!mounted || groups.docs.isEmpty) {
      return false;
    }

    final groupId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اختاري المجموعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final group in groups.docs)
                ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: Text(
                    group.data()['name']?.toString() ?? 'رفقتي',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop(group.id);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (groupId == null) return false;

    await GroupService.instance.sendLocation(
      groupId,
      latitude,
      longitude,
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        open: _handleHomeNavigation,
      ),

      const LostHelpScreen(),

      const GroupsScreen(),

      const RifqaProfileScreen(),

      AskRifqaScreen(
        onShareLocationWithGroup: _shareLocationWithGroup,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: i,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: _selectTab,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.softGreen,
          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.sos_outlined),
              selectedIcon: Icon(Icons.sos_rounded),
              label: 'أنا تائه',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'رفقتي',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'اسأل رفقة',
            ),
          ],
        ),
      ),
    );
  }
}
