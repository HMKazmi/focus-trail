import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium frosted-glass style card with enhanced glassmorphism effects.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurStrength;
  final bool showGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.borderRadius = 24,
    this.blurStrength = 20,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: showGlow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius + 4),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withAlpha(isDark ? 30 : 20),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: cs.tertiary.withAlpha(isDark ? 20 : 15),
                  blurRadius: 60,
                  spreadRadius: -20,
                  offset: const Offset(-20, 20),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        cs.surfaceContainerHighest.withAlpha(140),
                        cs.surfaceContainerHigh.withAlpha(100),
                      ]
                    : [
                        cs.surface.withAlpha(220),
                        cs.surfaceContainerLow.withAlpha(180),
                      ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                width: 1.5,
                color: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withAlpha(30),
                          Colors.white.withAlpha(10),
                        ]
                      : [
                          Colors.white.withAlpha(150),
                          Colors.white.withAlpha(60),
                        ],
                ).colors.first,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withAlpha(isDark ? 8 : 40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A smaller, more compact glass container for smaller UI elements.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHighest.withAlpha(100)
                : cs.surface.withAlpha(180),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withAlpha(isDark ? 20 : 80),
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
