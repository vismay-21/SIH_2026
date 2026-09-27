import 'package:flutter/material.dart';

import '../../models/api/api_models.dart';
import '../../models/api/api_response.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/shared_widgets.dart';
import 'customer_main_screen.dart';
import 'customer_register_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _authRepo = AuthRepository();
  final _emailController = TextEditingController(text: 'customer@example.com');
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
          _demoUsers = users.where((u) => u.role == 'customer').toList();
        });
      }
    } catch (_) {
      // Demo users list is convenience only; ignore failure if backend not yet reached
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final isHindi = loginLanguageHindiNotifier.value;
    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = isHindi
            ? 'कृपया ईमेल और पासवर्ड दोनों दर्ज करें।'
            : 'Please enter both email and password.',
      );
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
        role: 'customer',
      );

      if (!mounted) return;

      if (response.user.role != 'customer') {
        setState(() {
          _isLoading = false;
          _errorMessage = isHindi
              ? 'यह खाता ${response.user.role == 'worker' ? 'कारीगर' : response.user.role} के रूप में पंजीकृत है। कृपया संबंधित पोर्टल से लॉगिन करें।'
              : 'This account is registered as a ${response.user.role}. Please log in via the ${response.user.role} portal.';
        });
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const CustomerMainScreen()),
        (route) => false,
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
      role: 'Customer',
      roleIcon: Icons.home_repair_service_rounded,
      description: 'Sign in to post a job and connect with trusted workers.',
      emailController: _emailController,
      passwordController: _passwordController,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      extraContent: _demoUsers.isNotEmpty
          ? ValueListenableBuilder<bool>(
              valueListenable: loginLanguageHindiNotifier,
              builder: (context, isHindi, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? 'त्वरित डेमो खाते:' : 'Quick Demo Accounts:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _demoUsers.map((u) {
                      return ActionChip(
                        label: Text(
                          u.fullName.isNotEmpty ? u.fullName : u.email,
                        ),
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
              ),
            )
          : null,
      onLogin: _handleLogin,
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
