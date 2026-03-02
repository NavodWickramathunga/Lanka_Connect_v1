import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation types matching the React AnimatedIcon component.
enum IconAnimation { scale, rotate, pulse, bounce, wiggle, shake }

/// A widget that wraps an [Icon] with hover/tap-triggered animations.
/// Mirrors the React `AnimatedIcon` from the new UI/UX design.
class AnimatedIconWidget extends StatefulWidget {
  const AnimatedIconWidget({
    super.key,
    required this.icon,
    this.animation = IconAnimation.scale,
    this.size = 24,
    this.color,
    this.isActive = false,
    this.triggerOnTap = true,
    this.duration = const Duration(milliseconds: 400),
  });

  final IconData icon;
  final IconAnimation animation;
  final double size;
  final Color? color;
  final bool isActive;
  final bool triggerOnTap;
  final Duration duration;

  @override
  State<AnimatedIconWidget> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<AnimatedIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() {
    if (!widget.isActive) {
      _controller.forward(from: 0);
    }
  }

  void _onExit() {
    if (!widget.isActive) {
      _controller.reverse();
    }
  }

  void _onTap() {
    if (widget.triggerOnTap && !widget.isActive) {
      _controller.forward(from: 0).then((_) {
        if (mounted) _controller.reverse();
      });
    }
  }

  Widget _buildAnimatedChild(Widget child) {
    switch (widget.animation) {
      case IconAnimation.scale:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 1.0 + (_controller.value * 0.25);
            return Transform.scale(scale: scale, child: child);
          },
          child: child,
        );

      case IconAnimation.rotate:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: child,
            );
          },
          child: child,
        );

      case IconAnimation.pulse:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = 0.5 + (_controller.value * 0.5);
            final scale = 1.0 + (_controller.value * 0.15);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: child,
        );

      case IconAnimation.bounce:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final bounce = math.sin(_controller.value * math.pi) * -8;
            return Transform.translate(offset: Offset(0, bounce), child: child);
          },
          child: child,
        );

      case IconAnimation.wiggle:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = math.sin(_controller.value * math.pi * 4) * 0.15;
            return Transform.rotate(angle: angle, child: child);
          },
          child: child,
        );

      case IconAnimation.shake:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = math.sin(_controller.value * math.pi * 4) * 4;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      widget.icon,
      size: widget.size,
      color: widget.color,
    );

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTap: widget.triggerOnTap ? _onTap : null,
        child: _buildAnimatedChild(iconWidget),
      ),
    );
  }
}
