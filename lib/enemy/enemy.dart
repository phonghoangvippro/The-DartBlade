import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../collision/hitbox.dart';
import '../collision/hurtbox.dart';
import '../combat/damage.dart';
import '../core/config/game_config.dart';
import '../core/constants/game_constants.dart';
import '../core/services/audio_service.dart';
import '../core/utils/math_utils.dart';
import '../entities/character.dart';
import '../game/darkblade_game.dart';
import '../inventory/item.dart';
import '../world/pickup.dart';
import 'enemy_ai.dart';
import 'enemy_state.dart';

/// Data-driven enemy archetype.
class EnemyArchetype {
  const EnemyArchetype({
    required this.name,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.color,
    this.detectRange = GameConfig.defaultDetectRange,
    this.attackRange = GameConfig.defaultAttackRange,
    this.patrolSpeed = 40,
    this.chaseSpeed = 95,
    this.attackDuration = 0.5,
    this.recoverDuration = 0.6,
    this.soulsReward = 15,
    this.dropChance = 0.35,
    this.size = const Size(30, 44),
  });

  final String name;
  final double maxHp;
  final double attack;
  final double defense;
  final Color color;
  final double detectRange;
  final double attackRange;
  final double patrolSpeed;
  final double chaseSpeed;
  final double attackDuration;
  final double recoverDuration;
  final int soulsReward;
  final double dropChance;
  final Size size;

  static const hollowSoldier = EnemyArchetype(
    name: 'Hollow Soldier',
    maxHp: 45,
    attack: 10,
    defense: 2,
    color: Color(0xFF5A6B4E),
  );

  static const caveBat = EnemyArchetype(
    name: 'Cave Bat',
    maxHp: 24,
    attack: 7,
    defense: 0,
    color: Color(0xFF4E4260),
    detectRange: 190,
    chaseSpeed: 130,
    soulsReward: 10,
    size: Size(26, 24),
  );

  static const cursedKnight = EnemyArchetype(
    name: 'Cursed Knight',
    maxHp: 90,
    attack: 16,
    defense: 6,
    color: Color(0xFF6B3F3F),
    patrolSpeed: 30,
    chaseSpeed: 80,
    attackDuration: 0.7,
    recoverDuration: 0.9,
    soulsReward: 40,
    dropChance: 0.6,
    size: Size(36, 50),
  );
}

/// Regular enemy driven by [EnemyAi] (FR-019..FR-024).
class Enemy extends Character
    with HasGameReference<DarkbladeGame>
    implements EnemyBrainHost {
  Enemy({
    required super.position,
    required this.archetype,
  }) : super(
          size: Vector2(archetype.size.width, archetype.size.height),
          maxHp: archetype.maxHp,
        ) {
    priority = GameConstants.priorityEnemy;
  }

  final EnemyArchetype archetype;
  late final EnemyAi ai;
  late final AttackHitbox _meleeHitbox;
  final DamageCalculator _damageCalc = DamageCalculator();

  double _deadTimer = 0;
  double _hitboxWindow = 0;

  @override
  String get faction => 'enemy';

  @override
  Future<void> onLoad() async {
    ai = EnemyAi(
      host: this,
      detectRange: archetype.detectRange,
      attackRange: archetype.attackRange,
      patrolSpeed: archetype.patrolSpeed,
      chaseSpeed: archetype.chaseSpeed,
      attackDuration: archetype.attackDuration,
      recoverDuration: archetype.recoverDuration,
    );

    add(Hurtbox(
      owner: this,
      position: Vector2(2, 2),
      size: Vector2(size.x - 4, size.y - 4),
    ));

    _meleeHitbox = AttackHitbox(
      ownerFaction: faction,
      damageProvider: (_) {
        final r = _damageCalc.calculate(
          attack: archetype.attack,
          canCrit: false,
        );
        return DamageInfo(
          amount: r.amount,
          knockbackDirection: facing.toDouble(),
        );
      },
      size: Vector2(archetype.attackRange + 6, size.y * 0.8),
    );
    add(_meleeHitbox);
  }

  // -------------------------------------------------------------- brain host
  @override
  void moveHorizontal(double speed) => velocity.x = speed;

  @override
  void stopHorizontal() => velocity.x = 0;

  @override
  double get playerDirection =>
      game.player.absoluteCenter.x >= absoluteCenter.x ? 1 : -1;

  @override
  void performAttack() {
    _hitboxWindow = archetype.attackDuration * 0.6;
    AudioService.instance.playSfx('enemy_attack.wav');
  }

  // ------------------------------------------------------------------ update
  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      _deadTimer += dt;
      applyPhysics(dt);
      if (_deadTimer > 1.2) removeFromParent();
      return;
    }

    final player = game.player;
    ai.update(AiContext(
      distanceToPlayer:
          absoluteCenter.distanceTo(player.absoluteCenter),
      playerAlive: !player.isDead,
      dt: dt,
    ));

    // Attack hit window management (FR-022).
    if (_hitboxWindow > 0) {
      _hitboxWindow -= dt;
      _meleeHitbox.position = facing > 0
          ? Vector2(size.x - 4, size.y * 0.1)
          : Vector2(-archetype.attackRange - 2, size.y * 0.1);
      if (!_meleeHitbox.isActive) _meleeHitbox.activate();
      if (_hitboxWindow <= 0) _meleeHitbox.deactivate();
    }

    applyPhysics(dt);
  }

  // ------------------------------------------------------------------ combat
  @override
  void receiveDamage(DamageInfo info) {
    if (isDead || isInvincible) return;
    final amount =
        (info.amount - archetype.defense).clamp(1.0, double.infinity);
    health.damage(amount);
    game.spawnDamageNumber(
        absoluteCenter - Vector2(0, size.y / 2), amount, info.isCritical);

    if (health.isDead) {
      onDeath();
    } else {
      applyKnockback(info);
      ai.forceState(EnemyState.hurt);
      invincibleTimer = 0.1;
    }
  }

  @override
  void onDeath() {
    ai.forceState(EnemyState.dead);
    _meleeHitbox.deactivate();
    velocity.x = 0;
    AudioService.instance.playSfx('enemy_death.wav');

    // FR-023 / FR-024: reward souls + chance to drop an item.
    game.player.stats.souls += archetype.soulsReward;
    if (MathUtils.rng.nextDouble() < archetype.dropChance) {
      game.gameWorld.add(Pickup(
        position: absoluteCenter,
        item: _rollDrop(),
      ));
    }
  }

  Item _rollDrop() {
    final roll = MathUtils.rng.nextDouble();
    if (roll < 0.6) return Item.healthPotion;
    if (roll < 0.85) return Item.ironSword;
    return Item.knightArmor;
  }

  // ------------------------------------------------------------------ render
  @override
  void render(Canvas canvas) {
    canvas.save();
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    final t = animationTime;
    final baseColor = isDead
        ? archetype.color.withValues(alpha: 1 - (_deadTimer / 1.2))
        : (isHurt ? const Color(0xFFC24B4B) : archetype.color);
    final paint = Paint()..color = baseColor;

    if (isDead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.y - 10, size.x, 8),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
      return;
    }

    final bob = ai.state == EnemyState.chase || ai.state == EnemyState.patrol
        ? sin(t * 10).abs() * -2
        : sin(t * 2.5) * 1.2;

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.15, size.y * 0.25 + bob, size.x * 0.7,
            size.y * 0.55),
        const Radius.circular(4),
      ),
      paint,
    );
    // Head.
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.18 + bob), size.x * 0.22, paint);
    // Eye.
    canvas.drawCircle(
      Offset(size.x * 0.62, size.y * 0.16 + bob),
      2.2,
      Paint()
        ..color = ai.state == EnemyState.chase ||
                ai.state == EnemyState.attack
            ? const Color(0xFFFF5252)
            : const Color(0xFFCFCFCF),
    );
    // Legs.
    final legSwing = velocity.x.abs() > 1 ? sin(t * 12) * 4 : 0.0;
    canvas.drawRect(
        Rect.fromLTWH(size.x * 0.28 + legSwing, size.y * 0.72, 5,
            size.y * 0.28),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(size.x * 0.58 - legSwing, size.y * 0.72, 5,
            size.y * 0.28),
        paint);

    // Attack telegraph: weapon arm.
    if (ai.state == EnemyState.attack) {
      canvas.drawRect(
        Rect.fromLTWH(size.x * 0.8, size.y * 0.35, size.x * 0.7, 4),
        Paint()..color = const Color(0xFFB9B9C4),
      );
    }

    canvas.restore();

    // Health bar above the enemy.
    if (health.current < health.max) {
      const barW = 30.0;
      final x = (size.x - barW) / 2;
      canvas.drawRect(Rect.fromLTWH(x, -8, barW, 4),
          Paint()..color = const Color(0xAA000000));
      canvas.drawRect(
        Rect.fromLTWH(x, -8, barW * health.ratio, 4),
        Paint()..color = const Color(0xFFD64545),
      );
    }
  }
}
