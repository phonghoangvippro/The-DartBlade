import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/constants/game_constants.dart';
import '../core/services/audio_service.dart';
import '../game/darkblade_game.dart';

/// A bonfire-style checkpoint (FR-008): touching it sets the respawn point,
/// refills the player's health and saves the game.
class Checkpoint extends PositionComponent
    with HasGameReference<DarkbladeGame> {
  Checkpoint({required Vector2 position})
    : super(
        position: position,
        size: Vector2(24, 40),
        anchor: Anchor.bottomCenter,
      ) {
    priority = GameConstants.priorityPickup;
  }

  bool activated = false;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (activated) return;

    final player = game.player;
    if (!player.isDead && player.toRect().overlaps(toRect())) {
      activated = true;
      player.respawnPoint = Vector2(
        position.x - player.size.x / 2,
        position.y - player.size.y,
      );
      player.health.refill();
      game.showToast('Checkpoint reached - progress saved');
      game.saveProgress();
      AudioService.instance.playSfx('checkpoint.wav');
    }
  }

  @override
  void render(Canvas canvas) {
    // Sword planted in the ground, flame above when lit.
    final metal = Paint()..color = const Color(0xFF8B8B9E);
    canvas.drawRect(Rect.fromLTWH(size.x / 2 - 2, 12, 4, size.y - 12), metal);
    canvas.drawRect(Rect.fromLTWH(size.x / 2 - 8, 14, 16, 3), metal);

    if (activated) {
      final flicker = 2 + sin(_t * 8) * 1.5;
      canvas.drawCircle(
        Offset(size.x / 2, 8),
        7 + flicker,
        Paint()..color = const Color(0x337B2FF2),
      );
      canvas.drawCircle(
        Offset(size.x / 2, 8),
        4 + flicker / 2,
        Paint()..color = const Color(0xFFB388FF),
      );
    } else {
      canvas.drawCircle(
        Offset(size.x / 2, 8),
        4,
        Paint()..color = const Color(0xFF55555E),
      );
    }
  }
}
