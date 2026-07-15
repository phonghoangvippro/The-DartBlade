import 'dart:math';

import 'package:flame/components.dart';

import '../core/config/game_config.dart';

/// Result of a single damage computation.
class DamageResult {
  const DamageResult({
    required this.amount,
    required this.isCritical,
    this.blocked = false,
  });

  final double amount;
  final bool isCritical;
  final bool blocked;
}

/// Pure damage math (plan section 8):
///
/// ```
/// Damage = Attack * SkillMultiplier - Defense (+ Critical bonus)
/// Critical: random 5%, x2 damage
/// Block: reduces damage by [GameConfig.blockDamageReduction]
/// ```
class DamageCalculator {
  DamageCalculator({Random? random}) : _random = random ?? Random();

  final Random _random;

  DamageResult calculate({
    required double attack,
    double skillMultiplier = 1.0,
    double defense = 0,
    bool canCrit = true,
    bool targetBlocking = false,
    double critChance = GameConfig.critChance,
    double critMultiplier = GameConfig.critMultiplier,
  }) {
    var raw = attack * skillMultiplier - defense;

    final isCrit = canCrit && _random.nextDouble() < critChance;
    if (isCrit) raw *= critMultiplier;

    if (targetBlocking) raw *= (1 - GameConfig.blockDamageReduction);

    // A landed hit always deals at least 1 damage.
    final amount = max(1.0, raw);
    return DamageResult(
      amount: amount,
      isCritical: isCrit,
      blocked: targetBlocking,
    );
  }
}

/// A packaged hit travelling from an attacker's hitbox to a hurtbox.
class DamageInfo {
  const DamageInfo({
    required this.amount,
    required this.knockbackDirection,
    this.isCritical = false,
    this.knockbackForce = GameConfig.knockbackX,
    this.sourcePosition,
  });

  final double amount;

  /// -1 = push left, 1 = push right.
  final double knockbackDirection;
  final bool isCritical;
  final double knockbackForce;

  /// World-space center of the attacker/projectile when the hit connected.
  ///
  /// This lets defenders decide whether a frontal block should catch the hit
  /// even when knockback direction is not a reliable proxy for attack origin.
  final Vector2? sourcePosition;
}
