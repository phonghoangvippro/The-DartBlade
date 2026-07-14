import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/damage.dart';
import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

/// Floor spikes: deal contact damage to the player (collision matrix:
/// Player x Trap).
class SpikeTrap extends PositionComponent
    with HasGameReference<DarkbladeGame> {
  SpikeTrap({
    required Vector2 position,
    required double width,
    this.damage = 15,
  }) : super(position: position, size: Vector2(width, 14)) {
    priority = GameConstants.priorityPlatform;
  }

  final double damage;

  @override
  void update(double dt) {
    super.update(dt);
    final player = game.player;
    if (player.isDead || player.isInvincible) return;
    if (player.toRect().overlaps(toRect())) {
      player.receiveDamage(DamageInfo(
        amount: damage,
        knockbackDirection:
            player.absoluteCenter.x >= absoluteCenter.x ? 1 : -1,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF7A7A8C);
    const spikeWidth = 10.0;
    for (double x = 0; x + spikeWidth <= size.x + 0.1; x += spikeWidth) {
      final path = Path()
        ..moveTo(x, size.y)
        ..lineTo(x + spikeWidth / 2, 0)
        ..lineTo(x + spikeWidth, size.y)
        ..close();
      canvas.drawPath(path, paint);
    }
  }
}
