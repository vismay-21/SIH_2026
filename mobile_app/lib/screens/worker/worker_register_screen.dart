import 'package:flutter/material.dart';

import 'worker_login_screen.dart';
import '../../widgets/common/shared_widgets.dart';

class WorkerRegisterScreen extends StatelessWidget {
  const WorkerRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthRegisterLayout(
      role: 'Worker',
      roleIcon: Icons.handyman_rounded,
      description: 'Create your profile and start finding fair opportunities.',
      onComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const WorkerLoginScreen()),
        );
      },
      onLogin: () => Navigator.of(context).pop(),
    );
  }
}
