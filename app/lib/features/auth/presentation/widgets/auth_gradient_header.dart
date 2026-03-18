import 'package:flutter/material.dart';

/// Animated gradient header with logo for auth screens.
class AuthGradientHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  
  const AuthGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  State<AuthGradientHeader> createState() => _AuthGradientHeaderState();
}

class _AuthGradientHeaderState extends State<AuthGradientHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _rotateAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Animated Logo
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(top: 32),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary,
                  cs.tertiary,
                  cs.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withAlpha(isDark ? 80 : 100),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: cs.tertiary.withAlpha(isDark ? 60 : 80),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(-10, 20),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Inner glow
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.center,
                        colors: [
                          const Color.fromARGB(255, 0, 0, 0),
                          const Color.fromARGB(255, 0, 0, 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Icon
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 48,
                  ),
                  // child: Icon(
                  //   Icons.rocket_launch_rounded,
                  //   size: 48,
                  //   color: cs.onPrimary,
                  // ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Title with shimmer effect
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [cs.onSurface, cs.primary.withAlpha(200)]
                : [cs.onSurface, cs.primary],
          ).createShader(bounds),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle ?? 'Take charge of your productivity  ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withAlpha(180),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
