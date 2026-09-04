import 'package:flutter/material.dart';

import '../customer/customer_login_screen.dart';
import '../worker/worker_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CustomerLoginScreen(),
                  ),
                );
              },
              child: const Text('Customer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WorkerLoginScreen(),
                  ),
                );
              },
              child: const Text('Worker'),
            ),
          ],
        ),
      ),
    );
  }
}
