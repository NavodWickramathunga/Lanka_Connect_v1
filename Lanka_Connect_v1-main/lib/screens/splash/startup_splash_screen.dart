import 'dart:async';

import 'package:flutter/material.dart';

class StartupSplashScreen extends StatefulWidget {
  const StartupSplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<StartupSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final Animation<double> _contentOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.10, 0.75, curve: Curves.easeOut),
  );

  late final Animation<double> _contentScale = Tween<double>(
    begin: 0.90,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  late final Animation<Offset> _contentSlide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/splash_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF05606A), Color(0xFF033B42)],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _contentOpacity,
                child: SlideTransition(
                  position: _contentSlide,
                  child: ScaleTransition(
                    scale: _contentScale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Image.asset(
                        'assets/branding/splash_foreground.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const _FallbackBrand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBrand extends StatelessWidget {
  const _FallbackBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.handshake_rounded, color: Colors.white, size: 72),
        SizedBox(height: 14),
        Text(
          'LankaConnect',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Connecting Local Services Across Sri Lanka',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFE1F5F7),
            fontSize: 18,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
