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
import '../weapon/blade_wave.dart';
import 'boss_phase.dart';

/// Configuration for a boss placed in a level.
class BossArchetype {
  const BossArchetype({
    required this.name,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.color,
    this.soulsReward = 300,
  });

  final String name;
  final double maxHp;
  final double attack;
  final double defense;
  final Color color;
  final int soulsReward;

  static const forestGuardian = BossArchetype(
    name: 'Guardian of the Forgotten Forest',
    maxHp: 400,
    attack: 20,
    defense: 6,
    color: Color(0xFF3E5A3E),
  );

  static const darkKing = BossArchetype(
    name: 'The Dark King',
    maxHp: 650,
    attack: 26,
    defense: 9,
    color: Color(0xFF3A2C52),
    soulsReward: 1000,
  );
}

/// Multi-phase boss (FR-025..FR-027).
///
/// FSM: dormant -> intro -> [idle/walk/attack/skill/ultimate] -> dead,
/// with phase transitions driven by HP thresholds 70% / 30%.
class Boss extends Character with HasGameReference<DarkbladeGame> {
  Boss({
    required super.position,
    required this.archetype,
    this.isFinalBoss = false,
  }) : super(
          size: Vector2(64, 86),
          maxHp: archetype.maxHp,
        ) {
    priority = GameConstants.priorityEnemy;
  }

  final BossArchetype archetype;
  final bool isFinalBoss;

  BossPhase phase = BossPhase.phase1;
  BossState state = BossState.dormant;

  double _stateTimer = 0;
  double _attackCooldown = 0;
  double _deadTimer = 0;
  bool _raging = false;

  late final AttackHitbox _meleeHitbox;
  final DamageCalculator _damageCalc = DamageCalculator();

  BossPhaseConfig get phaseConfig => BossPhaseConfig.configs[phase]!;

  bool get isActivated => state != BossState.dormant;

  @override
  String get faction => 'enemy';

  @override
  Future<void> onLoad() async {
    add(Hurtbox(
      owner: this,
      position: Vector2(6, 6),
      size: Vector2(size.x - 12, size.y - 12),
    ));

    _meleeHitbox = AttackHitbox(
      ownerFaction: faction,
      damageProvider: (_) {
        final r = _damageCalc.calculate(
          attack: archetype.attack * phaseConfig.damageMultiplier,
          canCrit: false,
        );
        return DamageInfo(
          amount: r.amount,
          knockbackDirection: facing.toDouble(),
          knockbackForce: GameConfig.knockbackX * 1.4,
        );
      },
      size: Vector2(70, size.y * 0.7),
    );
    add(_meleeHitbox);
  }

  // ------------------------------------------------------------------ update
  @override
  void update(double dt) {
    super.update(dt);
    _stateTimer += dt;

    if (state == BossState.dead) {
      _deadTimer += dt;
      applyPhysics(dt);
      if (_deadTimer > 2.0) removeFromParent();
      return;
    }

    final player = game.player;
    final distance = absoluteCenter.distanceTo(player.absoluteCenter);

    switch (state) {
      case BossState.dormant:
        if (!player.isDead &&
            distance <= GameConfig.bossActivationRange) {
          _setState(BossState.intro);
          game.onBossActivated(this);
          AudioService.instance.playSfx('boss_roar.wav');
        }
        break;

      case BossState.intro:
        // Camera shake / intro moment (plan section 13).
        if (_stateTimer >= 1.5) _setState(BossState.idle);
        break;

      case BossState.idle:
        velocity.x = 0;
        if (player.isDead) break;
        facing = player.absoluteCenter.x >= absoluteCenter.x ? 1 : -1;
        if (_attackCooldown > 0) {
          _attackCooldown -= dt;
        } else {
          _chooseAction(distance);
        }
        if (distance > 90 && _attackCooldown > 0.4) {
          _setState(BossState.walk);
        }
        break;

      case BossState.walk:
        facing = player.absoluteCenter.x >= absoluteCenter.x ? 1 : -1;
        velocity.x = facing * phaseConfig.moveSpeed;
        if (_attackCooldown > 0) _attackCooldown -= dt;
        if (distance <= 80 || _attackCooldown <= 0) {
          _setState(BossState.idle);
        }
        break;

      case BossState.attack:
        velocity.x *= 0.85;
        final active = _stateTimer >= 0.25 && _stateTimer <= 0.55;
        _meleeHitbox.position = facing > 0
            ? Vector2(size.x - 10, size.y * 0.15)
            : Vector2(-60, size.y * 0.15);
        if (active && !_meleeHitbox.isActive) _meleeHitbox.activate();
        if (!active && _meleeHitbox.isActive) _meleeHitbox.deactivate();
        if (_stateTimer >= 0.8) {
          _meleeHitbox.deactivate();
          _attackCooldown = phaseConfig.attackCooldown;
          _setState(BossState.idle);
        }
        break;

      case BossState.skill:
        velocity.x = 0;
        // FR-026: volley of dark projectiles.
        if (_stateTimer >= 0.5 && _stateTimer < 0.52) _fireProjectile(0);
        if (_stateTimer >= 0.75 && _stateTimer < 0.77) _fireProjectile(-30);
        if (_stateTimer >= 1.0 && _stateTimer < 1.02) _fireProjectile(30);
        if (_stateTimer >= 1.4) {
          _attackCooldown = phaseConfig.attackCooldown;
          _setState(BossState.idle);
        }
        break;

      case BossState.ultimate:
        // Dash across the arena dealing heavy contact damage.
        velocity.x = facing * 420;
        final active = _stateTimer >= 0.2 && _stateTimer <= 0.8;
        _meleeHitbox.position = facing > 0
            ? Vector2(size.x - 10, size.y * 0.15)
            : Vector2(-60, size.y * 0.15);
        if (active && !_meleeHitbox.isActive) _meleeHitbox.activate();
        if (_stateTimer >= 0.9) {
          _meleeHitbox.deactivate();
          velocity.x = 0;
          _attackCooldown = phaseConfig.attackCooldown * 1.5;
          _setState(BossState.idle);
        }
        break;

      case BossState.dead:
        break;
    }

    applyPhysics(dt);
  }

  void _chooseAction(double distance) {
    final cfg = phaseConfig;
    final roll = MathUtils.rng.nextDouble();

    if (cfg.usesUltimate && roll < 0.25 && distance > 120) {
      _setState(BossState.ultimate);
      AudioService.instance.playSfx('boss_ultimate.wav');
      return;
    }
    if (cfg.usesSkill && (roll < 0.45 || distance > 140)) {
      _setState(BossState.skill);
      AudioService.instance.playSfx('boss_skill.wav');
      return;
    }
    if (distance <= 90) {
      _setState(BossState.attack);
      AudioService.instance.playSfx('boss_attack.wav');
    } else {
      _setState(BossState.walk);
    }
  }

  void _fireProjectile(double yOffset) {
    game.gameWorld.add(BladeWave(
      position: absoluteCenter + Vector2(facing * 40, yOffset),
      direction: facing,
      damage: archetype.attack * 0.8 * phaseConfig.damageMultiplier,
      faction: faction,
      maxDistance: 500,
    ));
  }

  void _setState(BossState next) {
    state = next;
    _stateTimer = 0;
  }

  // ------------------------------------------------------------------ combat
  @override
  void receiveDamage(DamageInfo info) {
    if (state == BossState.dormant || state == BossState.dead) return;
    if (isInvincible) return;

    final amount =
        (info.amount - archetype.defense).clamp(1.0, double.infinity);
    health.damage(amount);
    game.spawnDamageNumber(
        absoluteCenter - Vector2(0, size.y / 2), amount, info.isCritical);
    invincibleTimer = 0.05;
    hurtTimer = 0.15;

    _updatePhase();

    if (health.isDead) onDeath();
  }

  /// FR-025: phase transitions at 70% and 30% HP; FR-027 rage in phase 3.
  void _updatePhase() {
    final ratio = health.ratio;
    if (ratio <= GameConfig.bossPhase3Threshold &&
        phase != BossPhase.phase3) {
      phase = BossPhase.phase3;
      _raging = true;
      invincibleTimer = 0.8;
      game.shakeCamera(intensity: 8, duration: 0.6);
      game.showToast('${archetype.name} enters a RAGE!');
      AudioService.instance.playSfx('boss_rage.wav');
    } else if (ratio <= GameConfig.bossPhase2Threshold &&
        phase == BossPhase.phase1) {
      phase = BossPhase.phase2;
      game.shakeCamera(intensity: 5, duration: 0.4);
      game.showToast('${archetype.name} grows stronger...');
    }
  }

  @override
  void onDeath() {
    _setState(BossState.dead);
    _meleeHitbox.deactivate();
    velocity.setZero();
    game.player.stats.souls += archetype.soulsReward;
    game.onBossDefeated(this);
    AudioService.instance.playSfx('boss_death.wav');
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
    var color = isHurt ? const Color(0xFFD25858) : archetype.color;
    if (state == BossState.dead) {
      color = color.withValues(alpha: 1 - (_deadTimer / 2.0));
    }
    final paint = Paint()..color = color;

    if (state == BossState.dead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.y - 18, size.x, 16),
          const Radius.circular(4),
        ),
        paint,
      );
      canvas.restore();
      return;
    }

    final bob = sin(t * (_raging ? 6 : 2.5)) * 2;

    // Rage aura.
    if (_raging) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -4 + bob, size.x + 8, size.y + 4),
          const Radius.circular(10),
        ),
        Paint()
          ..color = const Color(0x33FF3030)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.12, size.y * 0.22 + bob, size.x * 0.76,
            size.y * 0.6),
        const Radius.circular(8),
      ),
      paint,
    );
    // Head with horns.
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.16 + bob), size.x * 0.2, paint);
    final horn = Path()
      ..moveTo(size.x * 0.36, size.y * 0.1 + bob)
      ..lineTo(size.x * 0.28, size.y * -0.04 + bob)
      ..lineTo(size.x * 0.44, size.y * 0.06 + bob)
      ..close();
    canvas.drawPath(horn, paint);
    final horn2 = Path()
      ..moveTo(size.x * 0.64, size.y * 0.1 + bob)
      ..lineTo(size.x * 0.72, size.y * -0.04 + bob)
      ..lineTo(size.x * 0.56, size.y * 0.06 + bob)
      ..close();
    canvas.drawPath(horn2, paint);

    // Eyes.
    final eyeColor =
        _raging ? const Color(0xFFFF2020) : const Color(0xFFFFA726);
    canvas.drawCircle(
        Offset(size.x * 0.58, size.y * 0.14 + bob), 3, Paint()..color = eyeColor);

    // Legs.
    canvas.drawRect(
        Rect.fromLTWH(size.x * 0.24, size.y * 0.8, 10, size.y * 0.2), paint);
    canvas.drawRect(
        Rect.fromLTWH(size.x * 0.62, size.y * 0.8, 10, size.y * 0.2), paint);

    // Greatsword during attacks.
    if (state == BossState.attack || state == BossState.ultimate) {
      final progress = MathUtils.clampDouble(_stateTimer / 0.6, 0, 1);
      canvas.save();
      canvas.translate(size.x * 0.8, size.y * 0.4 + bob);
      canvas.rotate(-pi / 2 + progress * pi * 0.9);
      canvas.drawRect(Rect.fromLTWH(0, -4, size.x * 1.2, 8),
          Paint()..color = const Color(0xFF6E6E85));
      canvas.restore();
    }

    canvas.restore();
  }
}
