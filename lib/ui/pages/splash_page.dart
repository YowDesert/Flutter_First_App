import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../theme/game_theme.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _floatController;
  late final AnimationController _tapController;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    if (const bool.fromEnvironment('FLUTTER_TEST')) {
      _floatController.value = 0.35;
    } else {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
    });

    final controller = context.read<GameController>();
    if (controller.settings.hapticOn) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {
        // Ignore haptic channel errors in environments without device feedback.
      }
    }

    await _tapController.forward(from: 0);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (context, animation, secondaryAnimation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: const HomePage(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleStart,
        child: Stack(
          children: [
            Positioned.fill(
              child: _SplashBackground(
                floatAnimation: _floatController,
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge(
                  [_introController, _tapController],
                ),
                builder: (context, child) {
                  final introT = Curves.easeOutCubic.transform(
                    _introController.value,
                  );
                  final tapT = Curves.easeOut.transform(_tapController.value);
                  final scale =
                      lerpDouble(0.9, 1.0, introT)! * (1 - (tapT * 0.03));
                  final opacity =
                      (0.35 + (introT * 0.65)) * (1 - (tapT * 0.25));
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: _SplashForeground(
                  floatAnimation: _floatController,
                  isStarting: _isStarting,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashForeground extends StatelessWidget {
  const _SplashForeground({
    required this.floatAnimation,
    required this.isStarting,
  });

  final Animation<double> floatAnimation;
  final bool isStarting;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoBadge(floatAnimation: floatAnimation),
          const SizedBox(height: 24),
          Text('Sudoku', style: GameTheme.title(context)),
          const SizedBox(height: 8),
          Text(
            'Daily Board. Quick Run. Chill Focus.',
            textAlign: TextAlign.center,
            style: GameTheme.slogan(context),
          ),
          const SizedBox(height: 52),
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              final wave =
                  (math.sin(floatAnimation.value * math.pi * 2) + 1) * 0.5;
              return Opacity(
                opacity: isStarting ? 0.95 : (0.55 + (wave * 0.45)),
                child: child,
              );
            },
            child: Text(
              isStarting ? 'Loading...' : 'Tap to Start',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({
    required this.floatAnimation,
  });

  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        final y = math.sin(floatAnimation.value * math.pi * 2) * 6;
        return Transform.translate(
          offset: Offset(0, y),
          child: child,
        );
      },
      child: Container(
        width: 114,
        height: 114,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xF7FFFFFF),
              Color(0xD8FFFFFF),
            ],
          ),
          border: Border.all(color: const Color(0xBBFFFFFF), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x292E7383),
              blurRadius: 22,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.grid_view_rounded,
            size: 52,
            color: palette.dailyAccent,
          ),
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({
    required this.floatAnimation,
  });

  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(floatAnimation.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.58, 1.0],
              colors: [
                palette.homeBackgroundTop,
                palette.homeBackgroundMid,
                palette.homeBackgroundBottom,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120 + (t * 14),
                left: -70 + (t * 18),
                child: _BackdropOrb(
                  size: 320,
                  color: palette.dailyAccent.withValues(alpha: 0.28),
                ),
              ),
              Positioned(
                top: 130 - (t * 20),
                right: -100 + (t * 16),
                child: _BackdropOrb(
                  size: 300,
                  color: palette.quickAccent.withValues(alpha: 0.24),
                ),
              ),
              Positioned(
                bottom: -130 + (t * 18),
                left: 10 - (t * 16),
                child: _BackdropOrb(
                  size: 300,
                  color: palette.successAccent.withValues(alpha: 0.22),
                ),
              ),
              Positioned(
                bottom: 120 + (t * 8),
                right: 24 + (t * 10),
                child: _BackdropOrb(
                  size: 190,
                  color: palette.dailyAccent.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
