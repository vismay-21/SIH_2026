import 'package:flutter/material.dart';

import 'customer_login_screen.dart';
import '../../widgets/common/shared_widgets.dart';

class CustomerRegisterScreen extends StatelessWidget {
  const CustomerRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthRegisterLayout(
      role: 'Customer',
      roleIcon: Icons.home_repair_service_rounded,
      description: 'Create an account to post jobs and find trusted workers.',
      onComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const CustomerLoginScreen()),
        );
      },
      onLogin: () => Navigator.of(context).pop(),
    );
  }
}
