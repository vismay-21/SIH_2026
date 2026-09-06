import 'package:flutter/material.dart';

import '../../models/customer_gig_workflow.dart';
import 'home/customer_home_screen.dart';
import 'navigation_2/customer_navigation_2_screen.dart';
import 'navigation_3/customer_navigation_3_screen.dart';
import 'navigation_4/customer_navigation_4_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key, this.initialIndex = 0, this.initialGig});

  final int initialIndex;
  final CustomerGig? initialGig;

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      const CustomerHomeScreen(),
      CustomerNavigation2Screen(initialGig: widget.initialGig),
      const CustomerNavigation3Screen(),
      const CustomerNavigation4Screen(),
    ];

    return Scaffold(
      body: destinations[_selectedIndex],
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
    );
  }
}
