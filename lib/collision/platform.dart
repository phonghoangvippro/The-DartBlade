import 'dart:ui';

import 'package:flame/components.dart';

import '../core/constants/game_constants.dart';

/// A solid, axis-aligned platform / wall / floor block.
///
/// Level geometry is a list of these; [PhysicsBody] resolves against them
/// with swept AABB checks per axis, giving pixel-accurate collision
/// (plan section 9) without a full physics engine.
class Platform extends PositionComponent {
  Platform({
    required Vector2 position,
    required Vector2 size,
    this.oneWay = false,
    this.color = const Color(0xFF3D3D4E),
    this.visible = true,
  }) : super(position: position, size: size) {
    priority = GameConstants.priorityPlatform;
  }

  /// One-way platforms can be jumped through from below.
  final bool oneWay;
  final Color color;
  final bool visible;

  Rect get rect => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
    // Subtle top edge highlight so geometry reads well with placeholder art.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 3),
      Paint()..color = const Color(0xFF55556B),
    );
  }
}
