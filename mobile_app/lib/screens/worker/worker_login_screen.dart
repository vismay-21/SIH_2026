import 'package:flutter/material.dart';

import '../../models/api/api_models.dart';
import '../../models/api/api_response.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/shared_widgets.dart';
import 'worker_main_screen.dart';
import 'worker_register_screen.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _authRepo = AuthRepository();
  final _emailController = TextEditingController(text: 'worker1@example.com');
  final _passwordController = TextEditingController(text: 'password123');

  bool _isLoading = false;
  String? _errorMessage;
  List<DemoUserItem> _demoUsers = [];

  @override
  void initState() {
    super.initState();
    _loadDemoUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDemoUsers() async {
    try {
      final users = await _authRepo.getDemoUsers();
      if (mounted) {
        setState(() {
          _demoUsers = users.where((u) => u.role == 'worker').toList();
        });
      }
    } catch (_) {
      // Ignore initial demo user fetch failure if backend offline
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authRepo.login(
        email: email,
        password: password,
        role: 'worker',
      );

      if (!mounted) return;

      if (response.user.role != 'worker') {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'This account is registered as a ${response.user.role}. Please log in via the ${response.user.role} portal.';
        });
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WorkerMainScreen()),
      );
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLoginLayout(
      role: 'Worker',
      roleIcon: Icons.handyman_rounded,
      description: 'Sign in to find fair opportunities and manage your work.',
      emailController: _emailController,
      passwordController: _passwordController,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      extraContent: _demoUsers.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Demo Accounts:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _demoUsers.map((u) {
                    return ActionChip(
                      label: Text(u.fullName.isNotEmpty ? u.fullName : u.email),
                      onPressed: () {
                        setState(() {
                          _emailController.text = u.email;
                          _passwordController.text = 'password123';
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            )
          : null,
      onLogin: _handleLogin,
      onRegister: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const WorkerRegisterScreen(),
          ),
        );
      },
    );
  }
}
