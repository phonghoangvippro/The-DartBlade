import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../collision/hitbox.dart';
import '../collision/hurtbox.dart';
import '../combat/damage.dart';
import '../core/config/game_config.dart';
import '../core/constants/game_constants.dart';
import '../core/services/audio_service.dart';
import '../core/utils/math_utils.dart';
import '../effects/darkblade_effects.dart';
import '../entities/character.dart';
import '../game/darkblade_game.dart';
import '../inventory/item.dart';
import '../world/pickup.dart';
import 'enemy_ai.dart';
import 'enemy_state.dart';

// =============================================================================
// ENEMY ARCHETYPES
// =============================================================================

class EnemyArchetype {
  final String name;
  final double maxHp;
  final double attack;
  final double defense;
  final Color color;
  final Color auraColor;
  final double detectRange;
  final double attackRange;
  final double patrolSpeed;
  final double chaseSpeed;
  final double attackDuration;
  final double recoverDuration;
  final int soulsReward;
  final double dropChance;
  final Size size;
  final EnemyType type;

  const EnemyArchetype({
    required this.name,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.color,
    required this.type,
    this.auraColor = const Color(0xFFFF4444),
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

  // Chapter 1: Village of Ashes
  static const zombie = EnemyArchetype(
    name: 'Zombie',
    maxHp: 40,
    attack: 8,
    defense: 1,
    color: Color(0xFF5A6B4E),
    type: EnemyType.zombie,
    patrolSpeed: 25,
    chaseSpeed: 70,
    attackDuration: 0.7,
    recoverDuration: 0.8,
    soulsReward: 10,
    dropChance: 0.3,
    size: Size(30, 44),
  );

  static const skeleton = EnemyArchetype(
    name: 'Skeleton',
    maxHp: 55,
    attack: 14,
    defense: 3,
    color: Color(0xFFC4B89E),
    auraColor: Color(0xFFFFAA44),
    type: EnemyType.skeleton,
    detectRange: 180,
    attackRange: 48,
    patrolSpeed: 35,
    chaseSpeed: 90,
    attackDuration: 0.5,
    recoverDuration: 0.7,
    soulsReward: 20,
    dropChance: 0.45,
    size: Size(32, 50),
  );

  // Chapter 2: Forest of Whispers
  static const shadowWolf = EnemyArchetype(
    name: 'Shadow Wolf',
    maxHp: 70,
    attack: 18,
    defense: 2,
    color: Color(0xFF1A1A2E),
    auraColor: Color(0xFF4444FF),
    type: EnemyType.shadowWolf,
    detectRange: 220,
    attackRange: 38,
    patrolSpeed: 50,
    chaseSpeed: 140,
    attackDuration: 0.35,
    recoverDuration: 0.5,
    soulsReward: 30,
    dropChance: 0.5,
    size: Size(40, 32),
  );

  static const spiritWitch = EnemyArchetype(
    name: 'Spirit Witch',
    maxHp: 45,
    attack: 20,
    defense: 1,
    color: Color(0xFF4A2A5A),
    auraColor: Color(0xFFAA44FF),
    type: EnemyType.spiritWitch,
    detectRange: 250,
    attackRange: 150,
    patrolSpeed: 20,
    chaseSpeed: 60,
    attackDuration: 0.8,
    recoverDuration: 1.0,
    soulsReward: 35,
    dropChance: 0.55,
    size: Size(28, 52),
  );
}

enum EnemyType { zombie, skeleton, shadowWolf, spiritWitch }

// =============================================================================
// ENEMY CLASS
// =============================================================================

class Enemy extends Character
    with HasGameReference<DarkbladeGame>
    implements EnemyBrainHost {
  Enemy({
    required super.position,
    required this.archetype,
    required this.saveId,
  }) : super(
         size: Vector2(archetype.size.width, archetype.size.height),
         maxHp: archetype.maxHp,
       ) {
    priority = GameConstants.priorityEnemy;
  }

  final EnemyArchetype archetype;
  final String saveId;
  late final EnemyAi ai;
  late final AttackHitbox _meleeHitbox;
  late final Hurtbox _hurtbox;
  final DamageCalculator _damageCalc = DamageCalculator();

  double _deadTimer = 0;
  double _hitboxWindow = 0;
  double _rangedCooldown = 0;

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

    _hurtbox = Hurtbox(
      owner: this,
      position: Vector2(2, 2),
      size: Vector2(size.x - 4, size.y - 4),
    );
    add(_hurtbox);

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
          sourcePosition: absoluteCenter.clone(),
        );
      },
      size: Vector2(archetype.attackRange + 6, size.y * 0.8),
    );
    add(_meleeHitbox);
  }

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

  @override
  void update(double dt) {
    if (game.phase != GamePhase.playing) return;

    final player = game.player;
    final distance = absoluteCenter.distanceTo(player.absoluteCenter);
    final nearby = distance <= 760;
    _hurtbox.collisionType = nearby
        ? CollisionType.passive
        : CollisionType.inactive;
    if (!nearby) {
      _meleeHitbox.deactivate();
      velocity.x = 0;
      return;
    }

    super.update(dt);

    if (isDead) {
      _deadTimer += dt;
      applyPhysics(dt);
      if (_deadTimer > 1.2) removeFromParent();
      return;
    }

    _rangedCooldown -= dt;
    // Ranged attack for spirit witch
    if (archetype.type == EnemyType.spiritWitch &&
        ai.state == EnemyState.chase &&
        distance < archetype.attackRange &&
        distance > 80 &&
        _rangedCooldown <= 0) {
      _fireRanged();
      _rangedCooldown = 2.0;
    }

    ai.update(
      AiContext(
        distanceToPlayer: distance,
        playerAlive: !player.isDead,
        dt: dt,
      ),
    );

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

  void _fireRanged() {
    game.spawnBladeWave(
      position: absoluteCenter + Vector2(facing * 20, 0),
      direction: facing,
      damage: archetype.attack * 0.7,
      faction: faction,
      maxDistance: 400,
      color: archetype.auraColor,
    );
    AudioService.instance.playSfx('enemy_attack.wav');
  }

  @override
  void receiveDamage(DamageInfo info) {
    if (isDead || isInvincible) return;
    final amount = (info.amount - archetype.defense).clamp(
      1.0,
      double.infinity,
    );
    health.damage(amount);
    game.spawnDamageNumber(
      absoluteCenter - Vector2(0, size.y / 2),
      amount,
      info.isCritical,
    );

    game.gameWorld.add(
      HitSparks(position: absoluteCenter, color: archetype.auraColor, count: 4),
    );

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
    game.onEnemyDefeated(saveId);

    game.player.stats.souls += archetype.soulsReward;

    game.gameWorld.add(
      DarkEnergyBurst(
        position: absoluteCenter,
        color: archetype.auraColor,
        duration: 0.3,
        maxRadius: 25,
      ),
    );

    if (MathUtils.rng.nextDouble() < archetype.dropChance) {
      game.gameWorld.add(Pickup(position: absoluteCenter, item: _rollDrop()));
    }
  }

  Item _rollDrop() {
    final roll = MathUtils.rng.nextDouble();
    if (roll < 0.6) return Item.healthPotion;
    if (roll < 0.85) return Item.ironSword;
    return Item.knightArmor;
  }

  @override
  void render(Canvas canvas) {
    if (game.playerReady &&
        absoluteCenter.distanceTo(game.player.absoluteCenter) > 760) {
      return;
    }
    canvas.save();
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    final t = animationTime;
    final baseColor = isDead
        ? archetype.color.withValues(alpha: 1 - (_deadTimer / 1.2))
        : (isHurt ? const Color(0xFFC24B4B) : archetype.color);

    if (isDead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.y - 10, size.x, 8),
          const Radius.circular(3),
        ),
        Paint()..color = baseColor,
      );
      canvas.restore();
      return;
    }

    switch (archetype.type) {
      case EnemyType.zombie:
        _renderZombie(canvas, t, baseColor);
      case EnemyType.skeleton:
        _renderSkeleton(canvas, t, baseColor);
      case EnemyType.shadowWolf:
        _renderShadowWolf(canvas, t, baseColor);
      case EnemyType.spiritWitch:
        _renderSpiritWitch(canvas, t, baseColor);
    }

    canvas.restore();

    if (health.current < health.max) {
      const barW = 30.0;
      final x = (size.x - barW) / 2;
      canvas.drawRect(
        Rect.fromLTWH(x, -8, barW, 4),
        Paint()..color = const Color(0xAA000000),
      );
      canvas.drawRect(
        Rect.fromLTWH(x, -8, barW * health.ratio, 4),
        Paint()..color = const Color(0xFFD64545),
      );
    }
  }

  void _renderZombie(Canvas canvas, double t, Color baseColor) {
    final bob = ai.state == EnemyState.chase
        ? sin(t * 10).abs() * -2
        : sin(t * 2) * 1.5;

    // Tattered body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.15,
          size.y * 0.28 + bob,
          size.x * 0.7,
          size.y * 0.5,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = baseColor,
    );

    // Head
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.18 + bob),
      size.x * 0.22,
      Paint()..color = const Color(0xFF6B7B5E),
    );

    // Empty eyes
    canvas.drawCircle(
      Offset(size.x * 0.38, size.y * 0.16 + bob),
      3,
      Paint()..color = const Color(0xFF000000),
    );
    canvas.drawCircle(
      Offset(size.x * 0.62, size.y * 0.16 + bob),
      3,
      Paint()..color = const Color(0xFF000000),
    );

    // Mouth tear
    canvas.drawLine(
      Offset(size.x * 0.3, size.y * 0.24 + bob),
      Offset(size.x * 0.7, size.y * 0.22 + bob),
      Paint()
        ..color = const Color(0xFF2A1A0A)
        ..strokeWidth = 2,
    );

    // Arms (shambling)
    final armSwing = sin(t * 4) * 3;
    canvas.drawLine(
      Offset(size.x * 0.2, size.y * 0.35 + bob),
      Offset(size.x * (-0.15) + armSwing, size.y * 0.45 + bob),
      Paint()
        ..color = baseColor
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(size.x * 0.8, size.y * 0.35 + bob),
      Offset(size.x * 1.15 - armSwing, size.y * 0.45 + bob),
      Paint()
        ..color = baseColor
        ..strokeWidth = 4,
    );

    // Legs
    final legSwing = ai.state == EnemyState.chase ? sin(t * 8) * 3 : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.25 + legSwing, size.y * 0.7, 5, size.y * 0.3),
      Paint()..color = baseColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.55 - legSwing, size.y * 0.7, 5, size.y * 0.3),
      Paint()..color = baseColor,
    );
  }

  void _renderSkeleton(Canvas canvas, double t, Color baseColor) {
    final bob = ai.state == EnemyState.chase
        ? sin(t * 10).abs() * -2
        : sin(t * 2.5) * 1.5;

    // Ribcage
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.2,
          size.y * 0.28 + bob,
          size.x * 0.6,
          size.y * 0.4,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = baseColor,
    );

    // Rib lines
    for (var i = 0; i < 4; i++) {
      final y = size.y * (0.32 + i * 0.08) + bob;
      canvas.drawLine(
        Offset(size.x * 0.25, y),
        Offset(size.x * 0.75, y),
        Paint()
          ..color = const Color(0xFF3A3A2A).withValues(alpha: 0.5)
          ..strokeWidth = 1.5,
      );
    }

    // Skull
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.16 + bob),
      size.x * 0.2,
      Paint()..color = baseColor,
    );

    // Eye sockets
    canvas.drawCircle(
      Offset(size.x * 0.38, size.y * 0.14 + bob),
      3.5,
      Paint()..color = const Color(0xFF1A1A0A),
    );
    canvas.drawCircle(
      Offset(size.x * 0.62, size.y * 0.14 + bob),
      3.5,
      Paint()..color = const Color(0xFF1A1A0A),
    );

    // Glowing eyes when aggro
    if (ai.state == EnemyState.chase || ai.state == EnemyState.attack) {
      final glow = Paint()
        ..color = const Color(
          0xFFFFAA44,
        ).withValues(alpha: 0.6 + sin(t * 4) * 0.3);
      canvas.drawCircle(Offset(size.x * 0.38, size.y * 0.14 + bob), 2, glow);
      canvas.drawCircle(Offset(size.x * 0.62, size.y * 0.14 + bob), 2, glow);
    }

    // Jaw
    canvas.drawLine(
      Offset(size.x * 0.32, size.y * 0.22 + bob),
      Offset(size.x * 0.68, size.y * 0.22 + bob),
      Paint()
        ..color = const Color(0xFF3A3A2A)
        ..strokeWidth = 2,
    );

    // Weapon arm (sword)
    if (ai.state == EnemyState.attack) {
      canvas.drawLine(
        Offset(size.x * 0.85, size.y * 0.35 + bob),
        Offset(size.x * 1.3, size.y * 0.25 + bob),
        Paint()
          ..color = const Color(0xFF8A8A7A)
          ..strokeWidth = 4,
      );
    }

    // Legs
    final legSwing = velocity.x.abs() > 1 ? sin(t * 12) * 3 : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.28 + legSwing, size.y * 0.7, 4, size.y * 0.3),
      Paint()..color = baseColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.58 - legSwing, size.y * 0.7, 4, size.y * 0.3),
      Paint()..color = baseColor,
    );
  }

  void _renderShadowWolf(Canvas canvas, double t, Color baseColor) {
    final bob = ai.state == EnemyState.chase
        ? sin(t * 12).abs() * -3
        : sin(t * 2) * 1.5;

    // Shadow aura
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.4 + bob),
      size.x * 0.48,
      Paint()..color = const Color(0x16000066),
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.1,
          size.y * 0.3 + bob,
          size.x * 0.8,
          size.y * 0.5,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Head
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.18 + bob),
      size.x * 0.2,
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Eyes
    final eyeColor =
        ai.state == EnemyState.chase || ai.state == EnemyState.attack
        ? const Color(0xFF4444FF)
        : const Color(0xFF222244);
    canvas.drawCircle(
      Offset(size.x * 0.4, size.y * 0.14 + bob),
      3,
      Paint()..color = eyeColor,
    );
    canvas.drawCircle(
      Offset(size.x * 0.6, size.y * 0.14 + bob),
      3,
      Paint()..color = eyeColor,
    );

    // Glowing eyes in chase
    if (ai.state == EnemyState.chase || ai.state == EnemyState.attack) {
      final glow = Paint()
        ..color = eyeColor.withValues(alpha: 0.5 + sin(t * 5) * 0.3);
      canvas.drawCircle(Offset(size.x * 0.4, size.y * 0.14 + bob), 2, glow);
      canvas.drawCircle(Offset(size.x * 0.6, size.y * 0.14 + bob), 2, glow);
    }

    // Ears
    final earPath = Path()
      ..moveTo(size.x * 0.35, size.y * 0.1 + bob)
      ..lineTo(size.x * 0.32, size.y * (-0.04) + bob)
      ..lineTo(size.x * 0.42, size.y * 0.06 + bob)
      ..close();
    canvas.drawPath(earPath, Paint()..color = const Color(0xFF1A1A2E));
    final earPath2 = Path()
      ..moveTo(size.x * 0.65, size.y * 0.1 + bob)
      ..lineTo(size.x * 0.68, size.y * (-0.04) + bob)
      ..lineTo(size.x * 0.58, size.y * 0.06 + bob)
      ..close();
    canvas.drawPath(earPath2, Paint()..color = const Color(0xFF1A1A2E));

    // Legs
    final legSwing = ai.state == EnemyState.chase ? sin(t * 14) * 4 : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.15 + legSwing, size.y * 0.72, 5, size.y * 0.28),
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.35 - legSwing, size.y * 0.72, 5, size.y * 0.28),
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.55 + legSwing, size.y * 0.72, 5, size.y * 0.28),
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.75 - legSwing, size.y * 0.72, 5, size.y * 0.28),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Tail
    canvas.drawLine(
      Offset(size.x * 0.85, size.y * 0.3 + bob),
      Offset(size.x * 1.1, size.y * 0.15 + sin(t * 3) * 5),
      Paint()
        ..color = const Color(0xFF1A1A2E)
        ..strokeWidth = 4,
    );
  }

  void _renderSpiritWitch(Canvas canvas, double t, Color baseColor) {
    final bob = sin(t * 3) * 2;

    // Spirit glow
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.3 + bob),
      size.x * 0.62,
      Paint()..color = const Color(0x164A2A7A),
    );

    // Floating robe
    final robePath = Path()
      ..moveTo(size.x * 0.1, size.y * 0.25 + bob)
      ..lineTo(size.x * 0.9, size.y * 0.25 + bob)
      ..lineTo(size.x * 1.05, size.y * 0.85 + bob)
      ..lineTo(size.x * (-0.05), size.y * 0.85 + bob)
      ..close();
    canvas.drawPath(
      robePath,
      Paint()..color = baseColor.withValues(alpha: 0.7),
    );

    // Head
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.14 + bob),
      size.x * 0.16,
      Paint()..color = const Color(0xFFE0D0E8),
    );

    // Hair (long, flowing)
    final hairPaint = Paint()..color = const Color(0xFF2A1A3A);
    canvas.drawLine(
      Offset(size.x * 0.35, size.y * 0.08 + bob),
      Offset(size.x * 0.2, size.y * 0.3 + sin(t * 2) * 5),
      hairPaint..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(size.x * 0.65, size.y * 0.08 + bob),
      Offset(size.x * 0.8, size.y * 0.3 + sin(t * 2 + 1) * 5),
      hairPaint..strokeWidth = 3,
    );

    // Eyes (glowing)
    final eyeColor =
        ai.state == EnemyState.chase || ai.state == EnemyState.attack
        ? const Color(0xFFAA44FF)
        : const Color(0xFF6644AA);
    final eyeGlow = Paint()
      ..color = eyeColor.withValues(alpha: 0.6 + sin(t * 3) * 0.3);
    canvas.drawCircle(Offset(size.x * 0.42, size.y * 0.12 + bob), 2.5, eyeGlow);
    canvas.drawCircle(Offset(size.x * 0.58, size.y * 0.12 + bob), 2.5, eyeGlow);

    // No legs (floating)
    // Ghostly trail
    final trailPaint = Paint()..color = baseColor.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.2,
          size.y * 0.8 + bob,
          size.x * 0.6,
          size.y * 0.15,
        ),
        const Radius.circular(10),
      ),
      trailPaint,
    );
  }
}
