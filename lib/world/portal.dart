import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

/// Gateway to the next map. Locked until the level's boss (if any) dies.
class Portal extends PositionComponent with HasGameReference<DarkbladeGame> {
  Portal({required Vector2 position})
    : super(
        position: position,
        size: Vector2(36, 56),
        anchor: Anchor.bottomCenter,
      ) {
    priority = GameConstants.priorityPickup;
  }

  bool unlocked = false;
  double _t = 0;
  bool _used = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (!unlocked || _used) return;

    final player = game.player;
    if (!player.isDead && player.toRect().overlaps(toRect())) {
      _used = true;
      game.goToNextLevel();
    }
  }

  @override
  void render(Canvas canvas) {
    final color = unlocked ? const Color(0xFF7B2FF2) : const Color(0xFF3A3A45);

    // Arch.
    final arch = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final rect = Rect.fromLTWH(4, 8, size.x - 8, size.y - 8);
    canvas.drawArc(
      Rect.fromLTWH(rect.left, rect.top - 10, rect.width, 40),
      pi,
      pi,
      false,
      arch,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + 10),
      Offset(rect.left, rect.bottom),
      arch,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + 10),
      Offset(rect.right, rect.bottom),
      arch,
    );

    if (unlocked) {
      // Swirling energy.
      final glow = Paint()..color = const Color(0x447B2FF2);
      canvas.drawOval(
        Rect.fromLTWH(8, 14 + sin(_t * 3) * 2, size.x - 16, size.y - 18),
        glow,
      );
    }
  }
}
