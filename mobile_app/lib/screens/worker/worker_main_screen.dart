import 'package:flutter/material.dart';

import 'home/worker_home_screen.dart';
import 'my_jobs/worker_navigation_3_screen.dart';
import 'opportunities/worker_navigation_2_screen.dart';
import 'profile/worker_navigation_4_screen.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  late int _selectedIndex = widget.initialIndex;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildTabNavigator(int index, Widget rootScreen) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute<void>(builder: (_) => rootScreen);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final currentNav = _navigatorKeys[_selectedIndex].currentState;
        if (currentNav != null && currentNav.canPop()) {
          currentNav.pop();
        } else if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
          final rootNav = Navigator.of(context, rootNavigator: true);
          if (rootNav.canPop()) {
            rootNav.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildTabNavigator(
              0,
              WorkerHomeScreen(
                onSelectTab: (idx) {
                  setState(() => _selectedIndex = idx);
                },
              ),
            ),
            _buildTabNavigator(1, const WorkerNavigation2Screen()),
            _buildTabNavigator(2, const WorkerNavigation3Screen()),
            _buildTabNavigator(3, const WorkerNavigation4Screen()),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (_selectedIndex == index) {
              _navigatorKeys[index].currentState?.popUntil(
                (route) => route.isFirst,
              );
            } else {
              setState(() => _selectedIndex = index);
            }
          },
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
      ),
    );
  }
}
