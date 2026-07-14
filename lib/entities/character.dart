import 'package:flame/components.dart';

import '../collision/hurtbox.dart';
import '../collision/physics_body.dart';
import '../combat/damage.dart';
import '../combat/health.dart';
import '../core/config/game_config.dart';

/// Base class for every living entity (Player, Enemy, Boss).
///
/// Provides: physics body, health, facing, hurt/knockback reaction,
/// invincibility timer and death bookkeeping.
abstract class Character extends PositionComponent
    with PhysicsBody
    implements Damageable {
  Character({
    required Vector2 position,
    required Vector2 size,
    required double maxHp,
  })  : health = Health(maxHp),
        super(position: position, size: size);

  final Health health;

  /// 1 = facing right, -1 = facing left.
  int facing = 1;

  double invincibleTimer = 0;
  double hurtTimer = 0;
  bool get isHurt => hurtTimer > 0;
  bool get isDead => health.isDead;

  /// Animation clock, advanced every frame; used by procedural painters.
  double animationTime = 0;

  @override
  bool get isInvincible => invincibleTimer > 0;

  @override
  void update(double dt) {
    super.update(dt);
    animationTime += dt;
    if (invincibleTimer > 0) invincibleTimer -= dt;
    if (hurtTimer > 0) hurtTimer -= dt;
  }

  @override
  void receiveDamage(DamageInfo info) {
    if (isDead || isInvincible) return;
    health.damage(info.amount);
    onDamaged(info);
    if (health.isDead) {
      onDeath();
    } else {
      applyKnockback(info);
      hurtTimer = 0.25;
    }
  }

  void applyKnockback(DamageInfo info) {
    velocity.x = info.knockbackDirection * info.knockbackForce;
    velocity.y = GameConfig.knockbackY;
  }

  /// Hook: damage was applied (update UI, flash, sfx...).
  void onDamaged(DamageInfo info) {}

  /// Hook: health reached zero.
  void onDeath();
}
