import 'dart:ui';

import 'package:flame/components.dart';

import '../core/config/game_config.dart';
import 'platform.dart';

/// Mixin providing gravity + axis-separated AABB collision against the
/// level's [Platform] list.
///
/// Movement is resolved per axis (X first, then Y) which prevents tunneling
/// through thin walls at normal speeds and gives crisp platformer feel.
mixin PhysicsBody on PositionComponent {
  final Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool gravityEnabled = true;

  /// The level provides its solid geometry through this callback.
  List<Platform> Function()? platformsProvider;

  /// Collision bounds relative to [position] (component top-left).
  Rect get bodyRect =>
      Rect.fromLTWH(position.x, position.y, size.x, size.y);

  void applyPhysics(double dt) {
    if (gravityEnabled) {
      velocity.y += GameConfig.gravity * dt;
      if (velocity.y > GameConfig.maxFallSpeed) {
        velocity.y = GameConfig.maxFallSpeed;
      }
    }

    final platforms = platformsProvider?.call() ?? const <Platform>[];

    // ---- X axis ----
    position.x += velocity.x * dt;
    var rect = bodyRect;
    for (final p in platforms) {
      if (p.oneWay) continue; // one-way platforms never block horizontally
      if (!rect.overlaps(p.rect)) continue;
      if (velocity.x > 0) {
        position.x = p.rect.left - size.x;
      } else if (velocity.x < 0) {
        position.x = p.rect.right;
      }
      velocity.x = 0;
      rect = bodyRect;
    }

    // ---- Y axis ----
    final wasFalling = velocity.y > 0;
    final previousBottom = rect.bottom;
    position.y += velocity.y * dt;
    rect = bodyRect;
    isOnGround = false;
    for (final p in platforms) {
      if (!rect.overlaps(p.rect)) continue;
      if (velocity.y > 0) {
        // Falling onto a platform. One-way platforms only stop us if we were
        // fully above them last frame.
        if (p.oneWay && previousBottom > p.rect.top + 1) continue;
        position.y = p.rect.top - size.y;
        velocity.y = 0;
        isOnGround = true;
      } else if (velocity.y < 0 && !p.oneWay) {
        position.y = p.rect.bottom;
        velocity.y = 0;
      }
      rect = bodyRect;
    }

    // Treat resting contact as grounded even when velocity got zeroed.
    if (!isOnGround && wasFalling == false && velocity.y == 0) {
      final probe = Rect.fromLTWH(
        position.x,
        position.y + size.y,
        size.x,
        2,
      );
      for (final p in platforms) {
        if (probe.overlaps(p.rect)) {
          isOnGround = true;
          break;
        }
      }
    }
  }
}
