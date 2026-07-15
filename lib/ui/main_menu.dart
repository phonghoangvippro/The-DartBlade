import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key, required this.game});

  final DarkbladeGame game;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSave = widget.game.saveService.hasSave;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value;
        final pulse = sin(t * 2 * pi) * 0.5 + 0.5;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF08040E), Color(0xFF140A20), Color(0xFF0A040E)],
            ),
          ),
          child: Stack(
            children: [
              // Dark particles overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _MenuParticlePainter(t: t),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with glow
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          const Color(0xFF7B2FF2).withValues(alpha: 0.6 + pulse * 0.4),
                          const Color(0xFFB388FF),
                          const Color(0xFF7B2FF2).withValues(alpha: 0.6 + pulse * 0.4),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'THE DARKBLADE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                          shadows: [
                            Shadow(color: Color(0xFF7B2FF2), blurRadius: 30),
                            Shadow(color: Color(0xFFFF0000), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A 2D Souls-like Action RPG',
                      style: TextStyle(
                        color: const Color(0xFFB0A0C0).withValues(alpha: 0.6 + pulse * 0.2),
                        fontSize: 14,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dark Fantasy  ·  Hack and Slash  ·  Metroidvania',
                      style: TextStyle(
                        color: const Color(0xFF7B2FF2).withValues(alpha: 0.4),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _MenuButton(
                      label: 'NEW GAME',
                      icon: Icons.whatshot,
                      onPressed: widget.game.startNewGame,
                    ),
                    if (hasSave) ...[
                      const SizedBox(height: 14),
                      _MenuButton(
                        label: 'CONTINUE',
                        icon: Icons.play_arrow,
                        onPressed: widget.game.continueGame,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _MenuButton(
                      label: 'SETTINGS',
                      icon: Icons.settings,
                      onPressed: () =>
                          widget.game.overlays.add(OverlayIds.settingsMenu),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'v1.0  ·  Press ESC to pause',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuParticlePainter extends CustomPainter {
  final double t;
  _MenuParticlePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    for (var i = 0; i < 30; i++) {
      final x = ((rng.nextDouble() + t * 0.02 + i * 0.1) % 1.0) * size.width;
      final y = ((rng.nextDouble() + t * 0.01 + i * 0.07) % 1.0) * size.height;
      final alpha = (sin(t * 2 * pi + i) * 0.5 + 0.5) * 0.3;
      paint.color = const Color(0xFF7B2FF2).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 1.5 + rng.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MenuParticlePainter oldDelegate) => true;
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 48,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE0C9FF),
          side: BorderSide(
            color: const Color(0xFF7B2FF2).withValues(alpha: 0.6),
          ),
          backgroundColor: const Color(0xFF1A0A2E).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onPressed: onPressed,
        label: Text(
          label,
          style: const TextStyle(letterSpacing: 5, fontSize: 16),
        ),
      ),
    );
  }
}
