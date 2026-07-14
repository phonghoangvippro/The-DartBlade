import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../combat/damage.dart';
import 'hurtbox.dart';

/// An attacking volume that deals damage to [Hurtbox]es of other factions
/// exactly once per activation (FR-010).
class AttackHitbox extends RectangleHitbox {
  AttackHitbox({
    required this.ownerFaction,
    required this.damageProvider,
    super.position,
    super.size,
    super.anchor,
  }) {
    collisionType = CollisionType.inactive;
  }

  /// Faction of the attacker; targets of the same faction are ignored.
  final String ownerFaction;

  /// Called lazily when a hit connects so damage reflects live stats.
  final DamageInfo Function(Damageable target) damageProvider;

  final Set<Damageable> _alreadyHit = {};
  bool _active = false;

  bool get isActive => _active;

  /// Arms the hitbox for a new swing.
  void activate() {
    _active = true;
    _alreadyHit.clear();
    collisionType = CollisionType.active;
  }

  void deactivate() {
    _active = false;
    collisionType = CollisionType.inactive;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, ShapeHitbox other) {
    super.onCollisionStart(intersectionPoints, other);
    _tryHit(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, ShapeHitbox other) {
    super.onCollision(intersectionPoints, other);
    // Also check during overlap: the hitbox may activate while volumes
    // already intersect (e.g. point-blank attacks).
    _tryHit(other);
  }

  void _tryHit(ShapeHitbox other) {
    if (!_active || other is! Hurtbox) return;
    final target = other.owner;
    if (target.faction == ownerFaction) return;
    if (target.isInvincible) return;
    if (_alreadyHit.contains(target)) return;
    _alreadyHit.add(target);
    target.receiveDamage(damageProvider(target));
  }
}
