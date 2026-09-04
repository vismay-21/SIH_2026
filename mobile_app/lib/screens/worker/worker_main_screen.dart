import 'package:flutter/material.dart';

import 'home/worker_home_screen.dart';
import 'navigation_2/worker_navigation_2_screen.dart';
import 'navigation_3/worker_navigation_3_screen.dart';
import 'navigation_4/worker_navigation_4_screen.dart';

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
      appBar: AppBar(title: const Text('Worker Main')),
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