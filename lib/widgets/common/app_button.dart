import 'package:flutter/material.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';

/// Modern Premium Button - 2026 Design
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    final buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: widget.isOutlined ? AppColors.accent : Colors.white,
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        } : null,
        onTapUp: widget.onPressed != null ? (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
        } : null,
        onTapCancel: widget.onPressed != null ? () {
          setState(() => _isPressed = false);
          _controller.reverse();
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.isOutlined 
              ? null 
              : LinearGradient(
                  colors: [
                    widget.backgroundColor ?? AppColors.accent,
                    (widget.backgroundColor ?? AppColors.accent).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            color: widget.isOutlined ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(16),
            border: widget.isOutlined
              ? Border.all(
                  color: widget.backgroundColor ?? AppColors.accent,
                  width: 2,
                )
              : null,
            boxShadow: !widget.isOutlined && widget.onPressed != null
              ? [
                  BoxShadow(
                    color: (widget.backgroundColor ?? AppColors.accent).withOpacity(_isPressed ? 0.3 : 0.5),
                    blurRadius: _isPressed ? 15 : 20,
                    offset: Offset(0, _isPressed ? 4 : 8),
                  ),
                ]
              : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(child: buttonContent),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Gradient Button with Glassmorphism - 2026
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.gradient,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 0.8).animate(
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        } : null,
        onTapUp: widget.onPressed != null ? (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
        } : null,
        onTapCancel: widget.onPressed != null ? () {
          setState(() => _isPressed = false);
          _controller.reverse();
        } : null,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: widget.width,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? AppColors.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(_glowAnimation.value),
                    blurRadius: _isPressed ? 20 : 30,
                    offset: Offset(0, _isPressed ? 6 : 10),
                    spreadRadius: _isPressed ? 0 : 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isLoading ? null : widget.onPressed,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.isLoading)
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              else ...[
                                if (widget.icon != null) ...[
                                  Icon(widget.icon, size: 22, color: Colors.white),
                                  const SizedBox(width: 12),
                                ],
                                Text(
                                  widget.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
