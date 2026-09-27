import 'package:flutter/material.dart';

import '../../screens/common/forgot_password_screen.dart';
import '../../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.isHindi = false});

  final bool compact;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 46,
          height: compact ? 38 : 46,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.home_work_rounded,
            color: Colors.white,
            size: compact ? 21 : 25,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHindi ? 'सहकार सेवा' : 'Sahakaar Seva',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                isHindi ? 'सहकारी घरेलू सेवाएँ' : 'Cooperative household services',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 19),
              const SizedBox(height: 14),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: warning ? AppColors.text : color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
    );
  }
}

final loginLanguageHindiNotifier = ValueNotifier<bool>(false);

class AuthLoginLayout extends StatelessWidget {
  const AuthLoginLayout({
    super.key,
    required this.role,
    required this.roleIcon,
    required this.description,
    required this.onLogin,
    required this.onRegister,
    this.onForgotPassword,
    this.emailController,
    this.passwordController,
    this.isLoading = false,
    this.errorMessage,
    this.extraContent,
  });

  final String role;
  final IconData roleIcon;
  final String description;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback? onForgotPassword;
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  final bool isLoading;
  final String? errorMessage;
  final Widget? extraContent;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loginLanguageHindiNotifier,
      builder: (context, isHindi, _) {
        final isWorker = role.toLowerCase() == 'worker';
        final effectiveRole = isHindi
            ? (isWorker ? 'कारीगर' : 'ग्राहक')
            : role;
        final effectiveHeading = isHindi
            ? (isWorker ? 'कारीगर लॉगिन' : 'ग्राहक लॉगिन')
            : '$role Login';
        final effectiveDescription = isHindi
            ? (isWorker
                ? 'उचित काम के अवसर पाने और अपना काम प्रबंधित करने के लिए साइन इन करें।'
                : 'काम पोस्ट करने और विश्वसनीय कारीगरों से जुड़ने के लिए साइन इन करें।')
            : description;
        final effectiveCardTitle = isHindi
            ? '$effectiveRole खाता'
            : '$role account';
        final effectiveEmailLabel = isHindi
            ? 'ईमेल या मोबाइल नंबर'
            : 'Email or mobile number';
        final effectivePasswordLabel = isHindi ? 'पासवर्ड' : 'Password';
        final effectiveForgotPassword =
            isHindi ? 'पासवर्ड भूल गए?' : 'Forgot password?';
        final effectiveLoginLabel = isHindi ? 'लॉगिन' : 'Login';
        final effectiveRegisterLabel =
            isHindi ? 'पंजीकरण करें' : 'Register';
        final effectiveSecurityNote = isHindi
            ? 'आपकी जानकारी पूरी तरह सुरक्षित और गोपनीय है।'
            : 'Your details stay private and secure.';
        final effectiveBackTooltip = isHindi ? 'वापस' : 'Back';

        String? translatedError = errorMessage;
        if (isHindi && errorMessage != null) {
          if (errorMessage == 'Please enter both email and password.') {
            translatedError = 'कृपया ईमेल और पासवर्ड दोनों दर्ज करें।';
          } else if (errorMessage!.contains('This account is registered as a')) {
            translatedError = errorMessage!.contains('worker')
                ? 'यह खाता कारीगर के रूप में पंजीकृत है। कृपया कारीगर पोर्टल से लॉगिन करें।'
                : 'यह खाता ग्राहक के रूप में पंजीकृत है। कृपया ग्राहक पोर्टल से लॉगिन करें।';
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: effectiveBackTooltip,
                          ),
                          const Spacer(),
                          // Language Switch Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                loginLanguageHindiNotifier.value =
                                    !loginLanguageHindiNotifier.value;
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isHindi
                                      ? AppColors.primary
                                      : (isDark
                                          ? const Color(0xFF202A27)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isHindi
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.muted.withValues(
                                                alpha: 0.3,
                                              )
                                            : AppColors.border),
                                    width: 1.4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0F000000),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.translate_rounded,
                                      size: 15,
                                      color: isHindi
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.accent
                                              : AppColors.primary),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isHindi ? 'English' : 'हिंदी',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isHindi
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white
                                                : AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          BrandMark(compact: true, isHindi: isHindi),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(roleIcon, color: AppColors.primary, size: 25),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        effectiveHeading,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        effectiveDescription,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (translatedError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  translatedError,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              effectiveCardTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: effectiveEmailLabel,
                                prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: effectivePasswordLabel,
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: onForgotPassword ??
                                    () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                child: Text(effectiveForgotPassword),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : PrimaryAction(
                                      label: effectiveLoginLabel,
                                      icon: Icons.login_rounded,
                                      onPressed: onLogin,
                                    ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onRegister,
                                icon:
                                    const Icon(Icons.person_add_alt_1_rounded),
                                label: Text(effectiveRegisterLabel),
                              ),
                            ),
                            if (extraContent != null) ...[
                              const SizedBox(height: 16),
                              extraContent!,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          effectiveSecurityNote,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AuthRegisterLayout extends StatelessWidget {
  const AuthRegisterLayout({
    super.key,
    required this.role,
    required this.roleIcon,
    required this.description,
    required this.onComplete,
    required this.onLogin,
  });

  final String role;
  final IconData roleIcon;
  final String description;
  final VoidCallback onComplete;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back',
                      ),
                      const Spacer(),
                      const BrandMark(compact: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(roleIcon, color: AppColors.primary, size: 25),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$role Register',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your details',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const TextField(
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const TextField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email or mobile number',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Create password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryAction(
                            label: 'Complete Registration',
                            icon: Icons.check_rounded,
                            onPressed: onComplete,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton.icon(
                      onPressed: onLogin,
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Already have an account? Login'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Your details stay private and secure.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: padding, child: child),
  );
}
