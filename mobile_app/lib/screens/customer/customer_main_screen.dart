import 'package:flutter/material.dart';

import '../../models/customer_gig_workflow.dart';
import 'home/customer_home_screen.dart';
import 'my_jobs/customer_navigation_2_screen.dart';
import 'alerts/customer_navigation_3_screen.dart';
import 'profile/customer_navigation_4_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key, this.initialIndex = 0, this.initialGig});

  final int initialIndex;
  final CustomerGig? initialGig;

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _selectedIndex = widget.initialIndex;
  int _homeRevision = 0;
  int _myJobsRevision = 0;

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _homeRevision++;
      if (index == 1) _myJobsRevision++;
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
              CustomerHomeScreen(
                key: ValueKey('cust_home_$_homeRevision'),
              ),
            ),
            _buildTabNavigator(
              1,
              CustomerNavigation2Screen(
                key: ValueKey('cust_jobs_$_myJobsRevision'),
                initialGig: widget.initialGig,
              ),
            ),
            _buildTabNavigator(2, const CustomerNavigation3Screen()),
            _buildTabNavigator(3, const CustomerNavigation4Screen()),
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
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'My jobs',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
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
