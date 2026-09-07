import 'package:flutter/material.dart';

import 'home/worker_home_screen.dart';
import 'opportunities/worker_navigation_2_screen.dart';
import 'my_jobs/worker_navigation_3_screen.dart';
import 'profile/worker_navigation_4_screen.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    WorkerHomeScreen(),
    WorkerNavigation2Screen(),
    WorkerNavigation3Screen(),
    WorkerNavigation4Screen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _destinations[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Opportunities',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'My jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
