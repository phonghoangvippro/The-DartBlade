import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/constants/game_constants.dart';
import '../core/services/audio_service.dart';
import '../game/darkblade_game.dart';
import '../inventory/item.dart';

/// A dropped item lying in the world; collected on player touch (FR-028).
class Pickup extends PositionComponent with HasGameReference<DarkbladeGame> {
  Pickup({
    required Vector2 position,
    required this.item,
  }) : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.center,
        ) {
    priority = GameConstants.priorityPickup;
  }

  final Item item;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    final player = game.player;
    if (!player.isDead &&
        player.toRect().overlaps(toRect().inflate(6))) {
      game.inventory.addItem(item);
      game.showToast('Picked up ${item.name}');
      AudioService.instance.playSfx('pickup.wav');
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final bobY = sin(_t * 4) * 3;
    final glow = Paint()
      ..color = item.color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()..color = item.color;

    final center = Offset(size.x / 2, size.y / 2 + bobY);
    canvas.drawCircle(center, 9, glow);

    switch (item.type) {
      case ItemType.consumable:
        // Potion flask.
        canvas.drawCircle(center, 5, core);
        canvas.drawRect(
            Rect.fromCenter(
                center: center.translate(0, -6), width: 3, height: 4),
            core);
        break;
      case ItemType.weapon:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-pi / 4);
        canvas.drawRect(const Rect.fromLTWH(-1.5, -8, 3, 16), core);
        canvas.drawRect(const Rect.fromLTWH(-4, 3, 8, 2), core);
        canvas.restore();
        break;
      case ItemType.armor:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 11, height: 12),
            const Radius.circular(3),
          ),
          core,
        );
        break;
      case ItemType.keyItem:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_t);
        canvas.drawRect(const Rect.fromLTWH(-5, -5, 10, 10), core);
        canvas.restore();
        break;
    }
  }
}
