import 'package:flutter/material.dart';

import 'customer_main_screen.dart';
import 'customer_register_screen.dart';
import '../../widgets/common/shared_widgets.dart';

class CustomerLoginScreen extends StatelessWidget {
  const CustomerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLoginLayout(
      role: 'Customer',
      roleIcon: Icons.home_repair_service_rounded,
      description: 'Sign in to post a job and connect with trusted workers.',
      onLogin: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const CustomerMainScreen()),
        );
      },
      onRegister: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CustomerRegisterScreen(),
          ),
        );
      },
    );
  }
}
