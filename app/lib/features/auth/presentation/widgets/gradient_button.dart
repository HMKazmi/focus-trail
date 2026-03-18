import 'package:flutter/material.dart';

/// A beautiful gradient button with glow effect.
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEnabled
                  ? [
                      cs.primary,
                      cs.tertiary,
                    ]
                  : [
                      cs.onSurface.withAlpha(30),
                      cs.onSurface.withAlpha(20),
                    ],
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: cs.primary.withAlpha(_isPressed ? 100 : 80),
                      blurRadius: _isPressed ? 15 : 20,
                      spreadRadius: _isPressed ? -5 : -2,
                      offset: Offset(0, _isPressed ? 5 : 8),
                    ),
                    BoxShadow(
                      color: cs.tertiary.withAlpha(_isPressed ? 60 : 50),
                      blurRadius: _isPressed ? 20 : 30,
                      spreadRadius: _isPressed ? -10 : -5,
                      offset: Offset(0, _isPressed ? 10 : 15),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Top shine
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.height / 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha(isEnabled ? 50 : 20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            cs.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        widget.text,
                        style: TextStyle(
                          color: isEnabled
                              ? cs.onPrimary
                              : cs.onSurface.withAlpha(100),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
