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
  int _homeRevision = 0;
  int _opportunitiesRevision = 0;
  int _myJobsRevision = 0;

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _homeRevision++;
      if (index == 1) _opportunitiesRevision++;
      if (index == 2) _myJobsRevision++;
    });
  }

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
          _onTabChanged(0);
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
                key: ValueKey('worker_home_$_homeRevision'),
                onSelectTab: (idx) {
                  _onTabChanged(idx);
                },
              ),
            ),
            _buildTabNavigator(
              1,
              WorkerNavigation2Screen(
                key: ValueKey('worker_opps_$_opportunitiesRevision'),
              ),
            ),
            _buildTabNavigator(
              2,
              WorkerNavigation3Screen(
                key: ValueKey('worker_jobs_$_myJobsRevision'),
              ),
            ),
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
              _onTabChanged(index);
            } else {
              _onTabChanged(index);
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
