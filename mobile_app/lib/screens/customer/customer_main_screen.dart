import 'package:flutter/material.dart';

import 'home/customer_home_screen.dart';
import 'navigation_2/customer_navigation_2_screen.dart';
import 'navigation_3/customer_navigation_3_screen.dart';
import 'navigation_4/customer_navigation_4_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    CustomerHomeScreen(),
    CustomerNavigation2Screen(),
    CustomerNavigation3Screen(),
    CustomerNavigation4Screen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Main')),
      body: _destinations[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.looks_two),
            label: 'Navigation 2',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.looks_3),
            label: 'Navigation 3',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.looks_4),
            label: 'Navigation 4',
          ),
        ],
      ),
    );
  }
}