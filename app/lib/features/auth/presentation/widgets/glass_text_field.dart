import 'package:flutter/material.dart';

/// A beautiful glass-style text field with gradient focus border.
class GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _borderAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _borderAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _isFocused
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withAlpha((80 * _borderAnimation.value).round()),
                      cs.tertiary.withAlpha((60 * _borderAnimation.value).round()),
                    ],
                  )
                : null,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: cs.primary.withAlpha((40 * _borderAnimation.value).round()),
                      blurRadius: 12 * _borderAnimation.value,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.all(_isFocused ? 2 : 0),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withAlpha(80)
              : cs.surfaceContainerLow.withAlpha(200),
          borderRadius: BorderRadius.circular(_isFocused ? 14 : 16),
          border: _isFocused
              ? null
              : Border.all(
                  color: cs.outlineVariant.withAlpha(60),
                  width: 1,
                ),
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            labelStyle: TextStyle(
              color: _isFocused ? cs.primary : cs.onSurfaceVariant,
              fontWeight: _isFocused ? FontWeight.w500 : FontWeight.normal,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _isFocused ? cs.primary : cs.onSurfaceVariant,
            ),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorStyle: TextStyle(
              color: cs.error,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
