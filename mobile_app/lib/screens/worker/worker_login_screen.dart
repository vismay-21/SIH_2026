import 'package:flutter/material.dart';

import 'worker_main_screen.dart';
import 'worker_register_screen.dart';
import '../../widgets/common/shared_widgets.dart';

class WorkerLoginScreen extends StatelessWidget {
  const WorkerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLoginLayout(
      role: 'Worker',
      roleIcon: Icons.handyman_rounded,
      description: 'Sign in to find fair opportunities and manage your work.',
      onLogin: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const WorkerMainScreen()),
        );
      },
      onRegister: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WorkerRegisterScreen()),
        );
      },
    );
  }
}
