import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/auth_gradient_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/gradient_button.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String _passwordValue = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
    
    // Listen for password changes
    _passCtrl.addListener(_onPasswordChanged);
  }
  
  void _onPasswordChanged() {
    setState(() => _passwordValue = _passCtrl.text);
  }

  @override
  void dispose() {
    _passCtrl.removeListener(_onPasswordChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim(),
        );
    if (ok && mounted) context.go('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        const AuthGradientHeader(
                          title: 'Create Account',
                          subtitle: 'Join FocusTrail Today',
                        ),
                        const SizedBox(height: 40),
                        GlassCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fill in your details',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                GlassTextField(
                                  controller: _nameCtrl,
                                  labelText: 'Full Name',
                                  prefixIcon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || v.isEmpty) ? 'Enter your name' : null,
                                ),
                                const SizedBox(height: 16),
                                GlassTextField(
                                  controller: _emailCtrl,
                                  labelText: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                                ),
                                const SizedBox(height: 16),
                                GlassTextField(
                                  controller: _passCtrl,
                                  labelText: 'Password',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.next,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return 'Min 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                GlassTextField(
                                  controller: _confirmPassCtrl,
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                  validator: (v) {
                                    if (v != _passCtrl.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                // Password strength indicator
                                _PasswordStrengthIndicator(password: _passwordValue),
                                const SizedBox(height: 24),
                                if (auth.error != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: cs.errorContainer.withAlpha(40),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.error.withAlpha(60),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: cs.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.error!,
                                            style: TextStyle(
                                              color: cs.error,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                GradientButton(
                                  text: 'Create Account',
                                  onPressed: auth.isLoading ? null : _submit,
                                  isLoading: auth.isLoading,
                                ),
                                const SizedBox(height: 20),
                                // Terms and conditions
                                Text(
                                  'By creating an account, you agree to our Terms of Service and Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant.withAlpha(150),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: cs.outlineVariant.withAlpha(80),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant.withAlpha(150),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: cs.outlineVariant.withAlpha(80),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: TextButton(
                                    onPressed: () => context.go('/login'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: cs.onSurfaceVariant,
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Already have an account? '),
                                          TextSpan(
                                            text: 'Sign In',
                                            style: TextStyle(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Theme toggle
                        GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode : Icons.light_mode,
                                color: cs.onSurfaceVariant,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDark ? 'Dark' : 'Light',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 24,
                                child: Switch(
                                  value: isDark,
                                  onChanged: (_) =>
                                      ref.read(themeModeProvider.notifier).toggle(),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  String get _label {
    switch (_strength) {
      case 0:
        return 'Enter password';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Very Strong';
    }
  }

  Color _getColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (_strength) {
      case 0:
        return cs.outlineVariant;
      case 1:
        return cs.error;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _getColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: index < _strength
                      ? color
                      : cs.outlineVariant.withAlpha(60),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            color: password.isEmpty ? cs.onSurfaceVariant.withAlpha(150) : color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
