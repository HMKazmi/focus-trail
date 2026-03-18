import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/auth_gradient_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/gradient_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;
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
    
    // Load remembered email
    _loadRememberedEmail();
  }
  
  void _loadRememberedEmail() {
    final box = Hive.box(HiveBoxes.settings);
    final savedEmail = box.get('rememberedEmail') as String?;
    final wasRemembered = box.get('rememberMe') as bool? ?? false;
    if (savedEmail != null && wasRemembered) {
      _emailCtrl.text = savedEmail;
      _rememberMe = true;
    }
  }
  
  Future<void> _saveRememberMe() async {
    final box = Hive.box(HiveBoxes.settings);
    if (_rememberMe) {
      await box.put('rememberedEmail', _emailCtrl.text.trim());
      await box.put('rememberMe', true);
    } else {
      await box.delete('rememberedEmail');
      await box.put('rememberMe', false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Save remember me preference before login
    await _saveRememberMe();
    
    final ok = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
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
                        const AuthGradientHeader(title: 'Welcome to FocusTrail'),
                        const SizedBox(height: 40),
                        GlassCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign in to continue',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 24),
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
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.length < 3) ? 'Min 3 characters' : null,
                                ),
                                const SizedBox(height: 8),
                                // Remember Me and Forgot Password row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Remember Me checkbox
                                    GestureDetector(
                                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Forgot password
                                    TextButton(
                                      onPressed: () {
                                        // TODO: Implement forgot password
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: cs.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
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
                                  text: 'Sign In',
                                  onPressed: auth.isLoading ? null : _submit,
                                  isLoading: auth.isLoading,
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
                                    onPressed: () => context.go('/register'),
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
                                          const TextSpan(text: "Don't have an account? "),
                                          TextSpan(
                                            text: 'Register',
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
