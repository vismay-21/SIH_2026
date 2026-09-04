import 'package:flutter/material.dart';

import 'worker_login_screen.dart';

class WorkerRegisterScreen extends StatelessWidget {
  const WorkerRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Register')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const WorkerLoginScreen(),
              ),
            );
          },
          child: const Text('Complete Registration'),
        ),
      ),
    );
  }
}
