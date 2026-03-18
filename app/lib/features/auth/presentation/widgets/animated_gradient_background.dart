import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated gradient background with floating orbs for auth pages.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _orbController;
  late Animation<double> _gradientAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    
    _orbController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _gradientAnimation = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_gradientAnimation, _orbController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1.0 + _gradientAnimation.value * 0.5,
                -1.0 + _gradientAnimation.value * 0.3,
              ),
              end: Alignment(
                1.0 - _gradientAnimation.value * 0.3,
                1.0 - _gradientAnimation.value * 0.5,
              ),
              colors: isDark
                  ? [
                      const Color(0xFF0D1B2A),
                      Color.lerp(
                        const Color(0xFF1B263B),
                        cs.primaryContainer.withAlpha(80),
                        _gradientAnimation.value,
                      )!,
                      const Color(0xFF0D1B2A),
                    ]
                  : [
                      Color.lerp(
                        const Color(0xFFF8F9FA),
                        cs.primaryContainer.withAlpha(60),
                        _gradientAnimation.value,
                      )!,
                      const Color(0xFFE9ECEF),
                      Color.lerp(
                        const Color(0xFFF8F9FA),
                        cs.tertiaryContainer.withAlpha(40),
                        _gradientAnimation.value,
                      )!,
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Floating orbs
              ..._buildFloatingOrbs(isDark, cs),
              // Main content
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
  
  List<Widget> _buildFloatingOrbs(bool isDark, ColorScheme cs) {
    final orbColors = isDark
        ? [
            cs.primary.withAlpha(25),
            cs.tertiary.withAlpha(20),
            cs.secondary.withAlpha(15),
            cs.primaryContainer.withAlpha(30),
          ]
        : [
            cs.primary.withAlpha(35),
            cs.tertiary.withAlpha(30),
            cs.secondary.withAlpha(25),
            cs.primaryContainer.withAlpha(40),
          ];
    
    return List.generate(6, (index) {
      final size = 100.0 + (index * 50.0);
      final offset = index * 0.15;
      final speed = 1.0 + (index * 0.3);
      
      return Positioned(
        left: _getOrbX(index, _orbController.value + offset, speed),
        top: _getOrbY(index, _orbController.value + offset, speed),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                orbColors[index % orbColors.length],
                orbColors[index % orbColors.length].withAlpha(0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: orbColors[index % orbColors.length],
                blurRadius: size / 2,
                spreadRadius: size / 4,
              ),
            ],
          ),
        ),
      );
    });
  }
  
  double _getOrbX(int index, double t, double speed) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseX = (index % 3) * (screenWidth / 3);
    final offset = math.sin(t * math.pi * 2 * speed) * 60;
    return baseX + offset;
  }
  
  double _getOrbY(int index, double t, double speed) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseY = (index ~/ 3) * (screenHeight / 2) + (index * 50);
    final offset = math.cos(t * math.pi * 2 * speed) * 80;
    return baseY + offset;
  }
}
