import 'package:flutter/material.dart';

import 'customer_login_screen.dart';

class CustomerRegisterScreen extends StatelessWidget {
  const CustomerRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Register')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const CustomerLoginScreen(),
              ),
            );
          },
          child: const Text('Complete Registration'),
        ),
      ),
    );
  }
}
