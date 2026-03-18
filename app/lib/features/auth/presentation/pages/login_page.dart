import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_gradient_background.dart';
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
    _fadeController.forward();
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 800;

    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: isWide
              ? _buildWideLayout(auth, cs, isDark)
              : _buildNarrowLayout(auth, cs, isDark),
        ),
      ),
    );
  }

  Widget _buildWideLayout(AuthState auth, ColorScheme cs, bool isDark) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(child: _buildBrandingPanel(cs, isDark)),
        // Right side - Form
        Expanded(
          child: Center(
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildForm(auth, cs, isDark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(AuthState auth, ColorScheme cs, bool isDark) {
    return Center(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(cs, isDark, compact: true),
                  const SizedBox(height: 32),
                  _buildForm(auth, cs, isDark),
                  const SizedBox(height: 24),
                  _buildThemeToggle(cs, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel(ColorScheme cs, bool isDark) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                  height: 150,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.track_changes,
                    size: 120,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App name
              const Text(
                'FocusTrail',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              const Text(
                'Track your productivity.\nAchieve your goals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              // Features
              _buildFeatureItem(Icons.offline_bolt_outlined, 'Offline-first sync'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.insights_outlined, 'Analytics dashboard'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.devices_outlined, 'Cross-platform'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLogo(ColorScheme cs, bool isDark, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(40),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: compact ? 80 : 120,
            height: compact ? 80 : 120,
            errorBuilder: (_, __, ___) => Icon(
              Icons.track_changes,
              size: compact ? 60 : 100,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'FocusTrail',
            style: TextStyle(
              fontSize: compact ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState auth, ColorScheme cs, bool isDark) {
    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Remember me',
                        style:
                            TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (auth.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: TextStyle(color: cs.error, fontSize: 13),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: Divider(color: cs.outlineVariant.withAlpha(80))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: TextStyle(
                        color: cs.onSurfaceVariant.withAlpha(150), fontSize: 13),
                  ),
                ),
                Expanded(
                    child: Divider(color: cs.outlineVariant.withAlpha(80))),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => context.go('/register'),
                style:
                    TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Register',
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(30),
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
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            child: Switch(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
