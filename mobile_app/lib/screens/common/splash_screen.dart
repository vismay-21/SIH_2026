import 'package:flutter/material.dart';

import 'role_selection_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const RoleSelectionScreen(),
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
