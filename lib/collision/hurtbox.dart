import 'package:flame/collisions.dart';

import '../combat/damage.dart';

/// Anything that can receive damage implements this.
abstract class Damageable {
  /// Faction id used to avoid friendly fire ('player', 'enemy').
  String get faction;

  bool get isInvincible;

  void receiveDamage(DamageInfo info);
}

/// Receiving collision volume attached to a [Damageable] owner (FR-011).
class Hurtbox extends RectangleHitbox {
  Hurtbox({
    required this.owner,
    super.position,
    super.size,
    super.anchor,
  }) {
    // Hurtboxes never initiate collision resolution themselves.
    collisionType = CollisionType.passive;
  }

  final Damageable owner;
}
