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
import '../effects/darkblade_effects.dart';
import '../entities/character.dart';
import '../game/darkblade_game.dart';
import '../story/dialogue.dart';
import 'boss_phase.dart';

// =============================================================================
// BOSS ARCHETYPES - 4 Unique Bosses from the Story
// =============================================================================

class BossArchetype {
  final String name;
  final double maxHp;
  final double attack;
  final double defense;
  final Color color;
  final Color auraColor;
  final int soulsReward;
  final BossBehavior behavior;

  const BossArchetype({
    required this.name,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.color,
    required this.auraColor,
    required this.behavior,
    this.soulsReward = 500,
  });

  // Chapter 1 Boss
  static const fallenKnight = BossArchetype(
    name: 'The Fallen Knight',
    maxHp: 350,
    attack: 18,
    defense: 5,
    color: Color(0xFF6E6E85),
    auraColor: Color(0xFFFF4444),
    behavior: BossBehavior.knight,
    soulsReward: 400,
  );

  // Chapter 2 Boss
  static const elderTreant = BossArchetype(
    name: 'Elder Treant',
    maxHp: 500,
    attack: 22,
    defense: 8,
    color: Color(0xFF2D4A2D),
    auraColor: Color(0xFF44FF44),
    behavior: BossBehavior.treant,
    soulsReward: 600,
  );

  // Chapter 3 Boss
  static const bloodQueen = BossArchetype(
    name: 'Blood Queen',
    maxHp: 450,
    attack: 24,
    defense: 6,
    color: Color(0xFF6B1A2A),
    auraColor: Color(0xFFFF2266),
    behavior: BossBehavior.queen,
    soulsReward: 800,
  );

  // Final Boss
  static const kingVarkhan = BossArchetype(
    name: 'King Varkhan',
    maxHp: 800,
    attack: 30,
    defense: 10,
    color: Color(0xFF1A0A2E),
    auraColor: Color(0xFFFF0000),
    behavior: BossBehavior.varkhan,
    soulsReward: 2000,
  );
}

enum BossBehavior { knight, treant, queen, varkhan }

// =============================================================================
// MAIN BOSS CLASS
// =============================================================================

class Boss extends Character with HasGameReference<DarkbladeGame> {
  Boss({
    required super.position,
    required this.archetype,
    this.isFinalBoss = false,
  }) : super(size: _initialSize(archetype.behavior), maxHp: archetype.maxHp) {
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
  double _flyHeight = 0;
  bool _teleported = false;
  int _skillStage = 0;
  bool _summonTriggered = false;
  bool _criticalLorePlayed = false;
  bool _deathLorePlayed = false;

  late final AttackHitbox _meleeHitbox;
  final DamageCalculator _damageCalc = DamageCalculator();
  final Random _rng = Random();
  late double _arenaMinX;
  late double _arenaMaxX;

  BossPhaseConfig get phaseConfig => BossPhaseConfig.configs[phase]!;

  bool get isActivated => state != BossState.dormant;

  static Vector2 _initialSize(BossBehavior behavior) {
    return switch (behavior) {
      BossBehavior.knight => Vector2(70, 90),
      BossBehavior.treant => Vector2(100, 130),
      BossBehavior.queen => Vector2(60, 100),
      BossBehavior.varkhan => Vector2(80, 110),
    };
  }

  double get _visualScale => switch (archetype.behavior) {
    BossBehavior.knight => 1.0,
    BossBehavior.treant => 1.5,
    BossBehavior.queen => 0.9,
    BossBehavior.varkhan => 1.2,
  };

  @override
  String get faction => 'enemy';

  @override
  Future<void> onLoad() async {
    _arenaMinX = max(20, position.x - 340);
    _arenaMaxX = min(
      game.currentLevel!.definition.worldSize.width - size.x - 20,
      position.x + 340,
    );
    add(
      Hurtbox(
        owner: this,
        position: Vector2(size.x * 0.1, size.y * 0.1),
        size: Vector2(size.x * 0.8, size.y * 0.8),
      ),
    );

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
          sourcePosition: absoluteCenter.clone(),
        );
      },
      size: Vector2(size.x * 1.1, size.y * 0.7),
    );
    add(_meleeHitbox);
  }

  @override
  void update(double dt) {
    if (game.phase != GamePhase.playing && game.phase != GamePhase.gameOver) {
      return;
    }
    super.update(dt);
    _stateTimer += dt;

    if (state == BossState.dead) {
      _deadTimer += dt;
      applyPhysics(dt);
      if (_deadTimer > 2.5) removeFromParent();
      return;
    }

    final player = game.player;
    final distance = absoluteCenter.distanceTo(player.absoluteCenter);

    switch (state) {
      case BossState.dormant:
        if (!player.isDead && distance <= GameConfig.bossActivationRange) {
          _setState(BossState.intro);
          game.onBossActivated(this);
          AudioService.instance.playSfx('boss_roar.wav');
        }
        break;

      case BossState.intro:
        if (_stateTimer >= 2.0) _setState(BossState.idle);
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
        if (distance > 100 && _attackCooldown > 0.3) {
          _setState(BossState.walk);
        }
        break;

      case BossState.walk:
        facing = player.absoluteCenter.x >= absoluteCenter.x ? 1 : -1;
        velocity.x = facing * phaseConfig.moveSpeed;
        if (_attackCooldown > 0) _attackCooldown -= dt;
        if (distance <= 90 || _attackCooldown <= 0) {
          _setState(BossState.idle);
        }
        break;

      case BossState.attack:
        velocity.x *= 0.85;
        final active = _stateTimer >= 0.25 && _stateTimer <= 0.55;
        _meleeHitbox.position = _hitboxPos();
        if (active && !_meleeHitbox.isActive) _meleeHitbox.activate();
        if (!active && _meleeHitbox.isActive) _meleeHitbox.deactivate();
        if (_stateTimer >= 0.8) {
          _meleeHitbox.deactivate();
          _attackCooldown =
              phaseConfig.attackCooldown *
              (archetype.behavior == BossBehavior.varkhan ? 0.7 : 1.0);
          _setState(BossState.idle);
        }
        break;

      case BossState.skill:
        velocity.x = 0;
        _performSkill();
        break;

      case BossState.ultimate:
        velocity.x = facing * 420;
        final active = _stateTimer >= 0.2 && _stateTimer <= 0.8;
        _meleeHitbox.position = _hitboxPos();
        if (active && !_meleeHitbox.isActive) _meleeHitbox.activate();
        if (_stateTimer >= 0.9) {
          _meleeHitbox.deactivate();
          velocity.x = 0;
          _attackCooldown = phaseConfig.attackCooldown * 1.5;
          _setState(BossState.idle);
        }
        break;

      case BossState.summon:
        velocity.x = 0;
        if (_stateTimer >= 0.8 && !_summonTriggered) {
          _summonTriggered = true;
          _summonMinions();
        }
        if (_stateTimer >= 1.5) {
          _attackCooldown = phaseConfig.attackCooldown;
          _setState(BossState.idle);
        }
        break;

      case BossState.teleport:
        velocity.x = 0;
        if (_stateTimer >= 0.3 && !_teleported) {
          _teleported = true;
          final side = _rng.nextBool() ? -1 : 1;
          position.x = (game.player.position.x + side * 200).clamp(
            _arenaMinX,
            _arenaMaxX,
          );
          game.shakeCamera(intensity: 4, duration: 0.2);
          game.gameWorld.add(
            DarkEnergyBurst(
              position: absoluteCenter,
              color: archetype.auraColor,
              duration: 0.3,
            ),
          );
        }
        if (_stateTimer >= 0.8) {
          _teleported = false;
          _attackCooldown = 0.3;
          _setState(BossState.idle);
        }
        break;

      case BossState.fly:
        velocity.x = 0;
        _flyHeight = sin(_stateTimer * 3) * 20;
        position.y -= _flyHeight * dt * 5;
        if (_attackCooldown > 0) _attackCooldown -= dt;
        if (_attackCooldown <= 0) {
          _fireProjectile(0);
          _fireProjectile(-20);
          _fireProjectile(20);
          _attackCooldown = 1.5;
        }
        if (_stateTimer > 4) {
          _setState(BossState.idle);
        }
        break;

      case BossState.dead:
        break;
    }

    applyPhysics(dt);
    if (state != BossState.dead) {
      position.x = position.x.clamp(_arenaMinX, _arenaMaxX);
      if ((position.x <= _arenaMinX && velocity.x < 0) ||
          (position.x >= _arenaMaxX && velocity.x > 0)) {
        velocity.x = 0;
      }
    }
  }

  void _chooseAction(double distance) {
    final cfg = phaseConfig;
    final roll = _rng.nextDouble();
    final behavior = archetype.behavior;

    if (behavior == BossBehavior.varkhan) {
      if (phase == BossPhase.phase3 && roll < 0.3) {
        _setState(BossState.fly);
        AudioService.instance.playSfx('boss_skill.wav');
        return;
      }
      if (cfg.usesSkill && roll < 0.35) {
        _setState(BossState.skill);
        AudioService.instance.playSfx('boss_skill.wav');
        return;
      }
      if (phase == BossPhase.phase2 && roll < 0.5 && roll > 0.35) {
        _setState(BossState.teleport);
        return;
      }
      if (cfg.usesSummon && roll < 0.2) {
        _setState(BossState.summon);
        AudioService.instance.playSfx('boss_ultimate.wav');
        return;
      }
    } else if (behavior == BossBehavior.queen) {
      if (cfg.usesSkill && roll < 0.3) {
        _setState(BossState.teleport);
        return;
      }
      if (phase == BossPhase.phase3 && roll < 0.5) {
        _setState(BossState.skill);
        AudioService.instance.playSfx('boss_skill.wav');
        return;
      }
    } else if (behavior == BossBehavior.treant) {
      if (cfg.usesSkill && (roll < 0.4 || distance > 140)) {
        if (_rng.nextBool()) {
          _setState(BossState.skill);
        } else {
          _setState(BossState.ultimate);
        }
        AudioService.instance.playSfx('boss_skill.wav');
        return;
      }
    }

    if (cfg.usesUltimate && roll < 0.2 && distance > 120) {
      _setState(BossState.ultimate);
      AudioService.instance.playSfx('boss_ultimate.wav');
      return;
    }
    if (distance <= 90) {
      _setState(BossState.attack);
      AudioService.instance.playSfx('boss_attack.wav');
    } else {
      _setState(BossState.walk);
    }
  }

  void _performSkill() {
    final behavior = archetype.behavior;
    switch (behavior) {
      case BossBehavior.knight:
        if (_stateTimer >= 0.4 && _skillStage == 0) {
          _skillStage = 1;
          _fireProjectile(0);
        }
        if (_stateTimer >= 1.0) {
          _attackCooldown = phaseConfig.attackCooldown;
          _setState(BossState.idle);
        }
        break;
      case BossBehavior.treant:
        if (_stateTimer >= 0.5 && _skillStage == 0) {
          _skillStage = 1;
          for (var i = -2; i <= 2; i++) {
            _fireGroundProjectile(i * 30);
          }
        }
        if (_stateTimer >= 1.5) {
          _attackCooldown = phaseConfig.attackCooldown * 1.5;
          _setState(BossState.idle);
        }
        break;
      case BossBehavior.queen:
        if (_stateTimer >= 0.3 && _skillStage == 0) {
          _skillStage = 1;
          for (var i = -1; i <= 1; i++) {
            _fireProjectile(i * 25);
          }
          game.gameWorld.add(
            BloodSpatter(position: game.player.absoluteCenter, count: 15),
          );
        }
        if (_stateTimer >= 0.8) {
          _attackCooldown = phaseConfig.attackCooldown;
          _setState(BossState.idle);
        }
        break;
      case BossBehavior.varkhan:
        if (_stateTimer >= 0.3 && _skillStage == 0) {
          _skillStage = 1;
          for (var i = -3; i <= 3; i++) {
            _fireProjectile(i * 15);
          }
        }
        if (_stateTimer >= 0.7 && _skillStage == 1) {
          _skillStage = 2;
          for (var i = -2; i <= 2; i++) {
            _fireProjectile(i * 20);
          }
        }
        if (_stateTimer >= 1.6) {
          _attackCooldown = phaseConfig.attackCooldown;
          _setState(BossState.idle);
        }
        break;
    }
  }

  void _fireProjectile(double yOffset) {
    game.spawnBladeWave(
      position: absoluteCenter + Vector2(facing * 40, yOffset),
      direction: facing,
      damage: archetype.attack * 0.7 * phaseConfig.damageMultiplier,
      faction: faction,
      maxDistance: 500,
      color: archetype.auraColor,
    );
  }

  void _fireGroundProjectile(double xOffset) {
    game.spawnBladeWave(
      position: absoluteCenter + Vector2(xOffset, size.y * 0.4),
      direction: 0,
      damage: archetype.attack * 0.5 * phaseConfig.damageMultiplier,
      faction: faction,
      maxDistance: 400,
      color: const Color(0xFF44AA44),
      velocityY: 200,
    );
  }

  void _summonMinions() {
    AudioService.instance.playSfx('boss_rage.wav');
    game.shakeCamera(intensity: 5, duration: 0.3);
  }

  Vector2 _hitboxPos() {
    return facing > 0
        ? Vector2(size.x - 10, size.y * 0.15)
        : Vector2(-size.x * 0.85, size.y * 0.15);
  }

  void _setState(BossState next) {
    state = next;
    _stateTimer = 0;
    _skillStage = 0;
    _summonTriggered = false;
  }

  @override
  void receiveDamage(DamageInfo info) {
    if (state == BossState.dormant || state == BossState.dead) return;
    if (isInvincible) return;

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
      HitSparks(
        position: absoluteCenter - Vector2(0, size.y * 0.3),
        color: archetype.auraColor,
      ),
    );

    invincibleTimer = 0.05;
    hurtTimer = 0.15;
    _updatePhase();

    if (!health.isDead &&
        health.ratio <= 0.05 &&
        !_criticalLorePlayed &&
        archetype.behavior == BossBehavior.queen) {
      _criticalLorePlayed = true;
      _meleeHitbox.deactivate();
      game.showDialogue(const [
        DialogueLine(
          speaker: 'PRINCESS ELENIA',
          text: 'Xin lỗi...\n\nCha...',
          color: Color(0xFFFF7799),
        ),
      ]);
    }

    if (health.isDead) onDeath();
  }

  void _updatePhase() {
    final ratio = health.ratio;
    if (ratio <= GameConfig.bossPhase3Threshold && phase != BossPhase.phase3) {
      phase = BossPhase.phase3;
      _raging = true;
      invincibleTimer = 0.8;
      game.shakeCamera(intensity: 8, duration: 0.6);
      game.showToast('${archetype.name} enters RAGE!');
      AudioService.instance.playSfx('boss_rage.wav');
      if (archetype.behavior == BossBehavior.varkhan) {
        _meleeHitbox.deactivate();
        game.showDialogue(const [
          DialogueLine(
            speaker: 'KING VARKHAN',
            text:
                'Nếu phải trở thành quái vật...\nđể cứu con gái...\n\nTA SẼ GIẾT CẢ THẦN LINH!',
            color: Color(0xFFFF3344),
          ),
        ]);
      }
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
    AudioService.instance.playSfx('boss_death.wav');

    game.gameWorld.add(
      DarkEnergyBurst(
        position: absoluteCenter,
        color: archetype.auraColor,
        maxRadius: 120,
        duration: 1.0,
      ),
    );

    if (archetype.behavior == BossBehavior.knight) {
      game.player.unlockDash = true;
      game.showToast('DASH mastery increased!');
      if (!_deathLorePlayed) {
        _deathLorePlayed = true;
        game.showDialogue(const [
          DialogueLine(
            speaker: 'SIR ALDRIC',
            text: 'Cuối cùng...\n\nta cũng tìm được ngươi...',
            color: Color(0xFFE0C9FF),
          ),
        ], onComplete: () => game.onBossDefeated(this));
        return;
      }
    }
    game.onBossDefeated(this);
  }

  @override
  void render(Canvas canvas) {
    if (game.playerReady &&
        (absoluteCenter.x - game.player.absoluteCenter.x).abs() > 700) {
      return;
    }
    canvas.save();
    if (facing < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    final t = animationTime;
    var baseColor = isHurt ? const Color(0xFFD25858) : archetype.color;
    if (state == BossState.dead) {
      baseColor = baseColor.withValues(alpha: 1 - (_deadTimer / 2.5));
    }

    // Rage aura
    if (_raging || state == BossState.intro) {
      final pulse = sin(t * 5) * 0.15 + 0.85;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            -8 * _visualScale,
            -8 * _visualScale,
            size.x + 16 * _visualScale,
            size.y + 16 * _visualScale,
          ),
          const Radius.circular(20),
        ),
        Paint()..color = archetype.auraColor.withValues(alpha: 0.08 * pulse),
      );
    }

    // Phase aura
    if (phase != BossPhase.phase1) {
      final phaseColor = phase == BossPhase.phase2
          ? const Color(0x44FFAA00)
          : const Color(0x55FF2222);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -4, size.x + 8, size.y + 4),
          const Radius.circular(12),
        ),
        Paint()..color = phaseColor.withValues(alpha: 0.18),
      );
    }

    // ---- Boss-specific rendering ----
    switch (archetype.behavior) {
      case BossBehavior.knight:
        _renderFallenKnight(canvas, t, baseColor);
      case BossBehavior.treant:
        _renderElderTreant(canvas, t, baseColor);
      case BossBehavior.queen:
        _renderBloodQueen(canvas, t, baseColor);
      case BossBehavior.varkhan:
        _renderVarkhan(canvas, t, baseColor);
    }

    canvas.restore();
  }

  // ---- THE FALLEN KNIGHT ----
  void _renderFallenKnight(Canvas canvas, double t, Color baseColor) {
    if (state == BossState.dead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.y - 20, size.x, 16),
          const Radius.circular(4),
        ),
        Paint()..color = baseColor,
      );
      return;
    }

    final bob = sin(t * 2.5) * 2;
    final _s = _visualScale;

    // Armor body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.15,
          size.y * 0.25 + bob,
          size.x * 0.7,
          size.y * 0.55,
        ),
        Radius.circular(8 * _s),
      ),
      Paint()..color = baseColor,
    );

    // Armor trim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.15,
          size.y * 0.25 + bob,
          size.x * 0.7,
          size.y * 0.55,
        ),
        Radius.circular(8 * _s),
      ),
      Paint()
        ..color = const Color(0xFF8A8A9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Head / helmet
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.3,
          size.y * 0.08 + bob,
          size.x * 0.4,
          size.y * 0.2,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF5A5A72),
    );

    // Red eyes
    final eyeGlow = Paint()
      ..color = const Color(
        0xFFFF2222,
      ).withValues(alpha: 0.8 + sin(t * 3) * 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size.x * 0.42, size.y * 0.14 + bob), 3, eyeGlow);
    canvas.drawCircle(Offset(size.x * 0.58, size.y * 0.14 + bob), 3, eyeGlow);

    // Cloak
    final cloakPath = Path()
      ..moveTo(size.x * 0.1, size.y * 0.3 + bob)
      ..lineTo(size.x * (-0.15) + sin(t * 1.5) * 3, size.y * 0.9 + bob)
      ..lineTo(size.x * 0.4, size.y * 0.85 + bob)
      ..close();
    canvas.drawPath(
      cloakPath,
      Paint()..color = const Color(0xFF8B1A1A).withValues(alpha: 0.7),
    );

    // Greatsword
    if (state == BossState.attack || state == BossState.ultimate) {
      final progress = MathUtils.clampDouble(_stateTimer / 0.6, 0, 1);
      canvas.save();
      canvas.translate(size.x * 0.8, size.y * 0.4 + bob);
      canvas.rotate(-pi / 2 + progress * pi * 0.9);
      canvas.drawRect(
        Rect.fromLTWH(0, -3, size.x * 1.3, 6),
        Paint()..color = const Color(0xFF8A8A9E),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, -1, size.x * 1.3, 2),
        Paint()..color = const Color(0xFFB0B0C0),
      );
      canvas.restore();
    }

    // Legs
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.22, size.y * 0.78, size.x * 0.18, size.y * 0.22),
      Paint()..color = baseColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.6, size.y * 0.78, size.x * 0.18, size.y * 0.22),
      Paint()..color = baseColor,
    );
  }

  // ---- ELDER TREANT ----
  void _renderElderTreant(Canvas canvas, double t, Color baseColor) {
    if (state == BossState.dead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.y - 30, size.x, 20),
          const Radius.circular(4),
        ),
        Paint()..color = baseColor,
      );
      return;
    }

    final bob = sin(t * 1.5) * 3;

    // Massive trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.1,
          size.y * 0.2 + bob,
          size.x * 0.8,
          size.y * 0.65,
        ),
        const Radius.circular(12),
      ),
      Paint()..color = baseColor,
    );

    // Bark texture lines
    for (var i = 0; i < 6; i++) {
      final y = size.y * (0.3 + i * 0.1) + bob;
      canvas.drawLine(
        Offset(size.x * 0.18, y),
        Offset(size.x * 0.82, y),
        Paint()
          ..color = const Color(0xFF1A3A1A).withValues(alpha: 0.4)
          ..strokeWidth = 1.5,
      );
    }

    // Roots
    final rootPaint = Paint()..color = const Color(0xFF3A5A2A);
    final rootCount = (phase == BossPhase.phase3 ? 6 : 4);
    for (var i = 0; i < rootCount; i++) {
      final baseX = size.x * (0.2 + i * 0.15);
      final rootPath = Path()
        ..moveTo(baseX, size.y * 0.85 + bob)
        ..quadraticBezierTo(
          baseX + sin(t + i.toDouble()) * 15,
          size.y * 0.95,
          baseX + sin(t * 1.3 + i.toDouble()) * 25,
          size.y * 1.1,
        );
      canvas.drawPath(rootPath, rootPaint);
    }

    // Face on trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.3,
          size.y * 0.3 + bob,
          size.x * 0.12,
          size.y * 0.08,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1A1A0A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.58,
          size.y * 0.3 + bob,
          size.x * 0.12,
          size.y * 0.08,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1A1A0A),
    );

    // Glowing eyes
    final eyeColor = _raging
        ? const Color(0xFFFF2222)
        : const Color(0xFF44FF44);
    canvas.drawCircle(
      Offset(size.x * 0.36, size.y * 0.34 + bob),
      4,
      Paint()..color = eyeColor,
    );
    canvas.drawCircle(
      Offset(size.x * 0.64, size.y * 0.34 + bob),
      4,
      Paint()..color = eyeColor,
    );

    // Canopy / branches
    final branchPaint = Paint()..color = const Color(0xFF1A3A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * (-0.2),
          size.y * 0.0 + bob,
          size.x * 1.4,
          size.y * 0.25,
        ),
        const Radius.circular(20),
      ),
      branchPaint,
    );

    // Attack vines
    if (state == BossState.attack) {
      for (var i = 0; i < 3; i++) {
        final vinePath = Path()
          ..moveTo(size.x * (0.2 + i * 0.3), size.y * 0.5 + bob)
          ..quadraticBezierTo(
            size.x * (0.3 + i * 0.3) + sin(t * 5 + i.toDouble()) * 10,
            size.y * 0.3,
            size.x * (0.4 + i * 0.3),
            size.y * 0.1,
          );
        canvas.drawPath(
          vinePath,
          Paint()
            ..color = const Color(0xFF2A5A2A)
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  // ---- BLOOD QUEEN ----
  void _renderBloodQueen(Canvas canvas, double t, Color baseColor) {
    if (state == BossState.dead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.y - 20, size.x, 16),
          const Radius.circular(4),
        ),
        Paint()..color = baseColor,
      );
      return;
    }

    final bob = sin(t * 3) * 1.5;

    // Dress
    final dressPath = Path()
      ..moveTo(size.x * 0.1, size.y * 0.4 + bob)
      ..lineTo(size.x * 0.9, size.y * 0.4 + bob)
      ..lineTo(size.x * 1.1, size.y * 0.9 + bob)
      ..lineTo(size.x * (-0.1), size.y * 0.9 + bob)
      ..close();
    canvas.drawPath(dressPath, Paint()..color = const Color(0xFF6B1020));

    // Dress trim
    canvas.drawPath(
      dressPath,
      Paint()
        ..color = const Color(0xFFAA2244)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Corset / torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.25,
          size.y * 0.22 + bob,
          size.x * 0.5,
          size.y * 0.22,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF8B1525),
    );

    // White hair
    final hairPaint = Paint()..color = const Color(0xFFE8E8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.15,
          size.y * 0.0 + bob,
          size.x * 0.7,
          size.y * 0.2,
        ),
        const Radius.circular(10),
      ),
      hairPaint,
    );
    // Hair strands
    for (var i = 0; i < 4; i++) {
      final x = size.x * (0.2 + i * 0.18);
      canvas.drawLine(
        Offset(x, size.y * 0.1 + bob),
        Offset(x + sin(t + i.toDouble()) * 8, size.y * 0.3 + bob),
        Paint()
          ..color = const Color(0xFFD0D0E0)
          ..strokeWidth = 2,
      );
    }

    // Face
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.13 + bob),
      size.x * 0.15,
      Paint()..color = const Color(0xFFE8D8D0),
    );

    // Red eyes
    canvas.drawCircle(
      Offset(size.x * 0.42, size.y * 0.11 + bob),
      3,
      Paint()..color = const Color(0xFFFF0044),
    );
    canvas.drawCircle(
      Offset(size.x * 0.58, size.y * 0.11 + bob),
      3,
      Paint()..color = const Color(0xFFFF0044),
    );

    // Crown
    final crownPath = Path()
      ..moveTo(size.x * 0.35, size.y * 0.02 + bob)
      ..lineTo(size.x * 0.4, size.y * (-0.04) + bob)
      ..lineTo(size.x * 0.5, size.y * (-0.01) + bob)
      ..lineTo(size.x * 0.6, size.y * (-0.04) + bob)
      ..lineTo(size.x * 0.65, size.y * 0.02 + bob)
      ..close();
    canvas.drawPath(crownPath, Paint()..color = const Color(0xFFCCA840));

    // Wings (phase 2+)
    if (phase != BossPhase.phase1) {
      final wingPaint = Paint()
        ..color = const Color(0xFF4A0A1A).withValues(alpha: 0.55);
      for (var side = -1; side <= 1; side += 2) {
        final wingPath = Path()
          ..moveTo(size.x * 0.5, size.y * 0.3 + bob)
          ..quadraticBezierTo(
            size.x * (0.5 + side * 0.4),
            size.y * 0.1,
            size.x * (0.5 + side * 0.7),
            size.y * 0.3 + sin(t * 2) * 10,
          )
          ..quadraticBezierTo(
            size.x * (0.5 + side * 0.5),
            size.y * 0.6,
            size.x * 0.5,
            size.y * 0.5 + bob,
          )
          ..close();
        canvas.drawPath(wingPath, wingPaint);
      }
    }

    // Blood aura
    if (_raging) {
      canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.4 + bob),
        size.x * 0.5,
        Paint()..color = const Color(0x18FF0044),
      );
    }

    // Legs
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.28, size.y * 0.78, size.x * 0.12, size.y * 0.22),
      Paint()..color = const Color(0xFFE8D8D0),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.6, size.y * 0.78, size.x * 0.12, size.y * 0.22),
      Paint()..color = const Color(0xFFE8D8D0),
    );
  }

  // ---- KING VARKHAN ----
  void _renderVarkhan(Canvas canvas, double t, Color baseColor) {
    if (state == BossState.dead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.y - 24, size.x, 20),
          const Radius.circular(4),
        ),
        Paint()..color = baseColor,
      );
      return;
    }

    final bob = sin(t * 2) * 2;

    // Torn mantle trails behind him like living shadow.
    final mantle = Path()
      ..moveTo(size.x * 0.18, size.y * 0.28 + bob)
      ..quadraticBezierTo(
        -size.x * 0.35,
        size.y * 0.48,
        -size.x * 0.2 + sin(t * 1.7) * 8,
        size.y,
      )
      ..lineTo(size.x * 0.42, size.y * 0.82)
      ..close();
    canvas.drawPath(mantle, Paint()..color = const Color(0xCC090014));

    // Dark aura
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.5 + bob),
      size.x * 0.7,
      Paint()..color = const Color(0x121A0020),
    );

    // Armor body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.12,
          size.y * 0.22 + bob,
          size.x * 0.76,
          size.y * 0.55,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF1A0A2E),
    );

    // Lava veins split the armor from within.
    final armorCrack = Paint()
      ..color = const Color(
        0xFFFF3B18,
      ).withValues(alpha: 0.55 + sin(t * 4) * 0.25)
      ..strokeWidth = 2;
    canvas.drawPath(
      Path()
        ..moveTo(size.x * 0.3, size.y * 0.28 + bob)
        ..lineTo(size.x * 0.46, size.y * 0.43 + bob)
        ..lineTo(size.x * 0.38, size.y * 0.62 + bob),
      armorCrack,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.x * 0.72, size.y * 0.31 + bob)
        ..lineTo(size.x * 0.58, size.y * 0.5 + bob)
        ..lineTo(size.x * 0.7, size.y * 0.7 + bob),
      armorCrack,
    );

    // Armor trim (red glow)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.12,
          size.y * 0.22 + bob,
          size.x * 0.76,
          size.y * 0.55,
        ),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color(
          0xFFFF2200,
        ).withValues(alpha: 0.3 + sin(t * 2) * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Horned helmet
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x * 0.3,
          size.y * 0.05 + bob,
          size.x * 0.4,
          size.y * 0.2,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF0A0020),
    );

    // Horns
    final hornPaint = Paint()..color = const Color(0xFF2A0A3E);
    final hornL = Path()
      ..moveTo(size.x * 0.35, size.y * 0.08 + bob)
      ..lineTo(size.x * 0.22, size.y * (-0.08) + bob)
      ..lineTo(size.x * 0.38, size.y * 0.03 + bob)
      ..close();
    canvas.drawPath(hornL, hornPaint);
    final hornR = Path()
      ..moveTo(size.x * 0.65, size.y * 0.08 + bob)
      ..lineTo(size.x * 0.78, size.y * (-0.08) + bob)
      ..lineTo(size.x * 0.62, size.y * 0.03 + bob)
      ..close();
    canvas.drawPath(hornR, hornPaint);

    // Half-broken crown: one side still remembers the king he was.
    canvas.drawPath(
      Path()
        ..moveTo(size.x * 0.3, size.y * 0.04 + bob)
        ..lineTo(size.x * 0.34, size.y * -0.08 + bob)
        ..lineTo(size.x * 0.43, size.y * 0.0 + bob)
        ..lineTo(size.x * 0.5, size.y * -0.12 + bob)
        ..lineTo(size.x * 0.54, size.y * 0.04 + bob)
        ..close(),
      Paint()..color = const Color(0xFF8C6738),
    );

    // Glowing eyes (void black with red flame)
    canvas.drawCircle(
      Offset(size.x * 0.42, size.y * 0.12 + bob),
      4,
      Paint()..color = const Color(0xFF000000),
    );
    canvas.drawCircle(
      Offset(size.x * 0.58, size.y * 0.12 + bob),
      4,
      Paint()..color = const Color(0xFF000000),
    );
    final flamePaint = Paint()
      ..color = const Color(
        0xFFFF4400,
      ).withValues(alpha: 0.6 + sin(t * 3) * 0.3);
    canvas.drawCircle(
      Offset(size.x * 0.42, size.y * 0.12 + bob),
      3,
      flamePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.58, size.y * 0.12 + bob),
      3,
      flamePaint,
    );

    // Darkblade (the actual sword)
    final bladeProgress = sin(t * 1.5) * 0.15 + 0.85;
    canvas.save();
    canvas.translate(size.x * (-0.1), size.y * 0.2 + bob);
    canvas.rotate(-pi / 5 + sin(t) * 0.05);

    // Darkblade glow
    canvas.drawRect(
      Rect.fromLTWH(-3, -size.y * 0.1, size.x * 1.5 + 6, size.y * 0.9 + 6),
      Paint()
        ..color = const Color(
          0x44FF0000,
        ).withValues(alpha: bladeProgress * 0.22),
    );
    // Blade body
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * 1.5, size.y * 0.9),
      Paint()..color = const Color(0xFF0A0018),
    );
    // Cracked lava lines
    final crackPaint = Paint()
      ..color = const Color(0xFFFF4400).withValues(alpha: bladeProgress);
    canvas.drawLine(
      Offset(0, size.y * 0.2),
      Offset(size.x * 1.5, size.y * 0.3),
      crackPaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.3, 0),
      Offset(size.x * 0.5, size.y * 0.9),
      crackPaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.8, size.y * 0.1),
      Offset(size.x * 0.9, size.y * 0.8),
      crackPaint,
    );

    canvas.restore();

    // Phase 2: dark wings. Phase 3 opens three pairs.
    if (phase != BossPhase.phase1) {
      final wingPaint = Paint()
        ..color = const Color(0xFF0A0020).withValues(alpha: 0.62);
      final wingPairs = phase == BossPhase.phase3 ? 3 : 1;
      for (var pair = 0; pair < wingPairs; pair++) {
        for (var side = -1; side <= 1; side += 2) {
          final spread = 1.0 - pair * 0.18;
          final lift = pair * size.y * 0.12;
          final wingPath = Path()
            ..moveTo(size.x * 0.5, size.y * 0.2 + bob + lift)
            ..quadraticBezierTo(
              size.x * (0.5 + side * 0.5),
              size.y * (-0.1) + lift,
              size.x * (0.5 + side * spread),
              size.y * 0.1 + lift + sin(t * 2 + pair) * 8,
            )
            ..quadraticBezierTo(
              size.x * (0.5 + side * 0.7),
              size.y * 0.5,
              size.x * 0.5,
              size.y * 0.35 + bob,
            )
            ..close();
          canvas.drawPath(wingPath, wingPaint);

          // Wing membrane lines
          for (var i = 0; i < 3; i++) {
            final path = Path()
              ..moveTo(size.x * 0.5, size.y * 0.2 + bob)
              ..lineTo(
                size.x * (0.5 + side * (0.5 + i * 0.2)),
                size.y * (0.1 + i * 0.12) + sin(t + i.toDouble()) * 5,
              );
            canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFF1A0A3E).withValues(alpha: 0.5)
                ..strokeWidth = 1.5,
            );
          }
        }
      }
    }

    // Phase 3: Shadow Titan form
    if (phase == BossPhase.phase3) {
      // Larger aura
      canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.5 + bob),
        size.x * 0.9,
        Paint()..color = const Color(0x16FF0000),
      );
      // Shadow tendrils
      final tendrilPaint = Paint()
        ..color = const Color(0x24FF0000)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < 5; i++) {
        final angle = pi * 2 * i / 5 + t * 0.5;
        final path = Path()
          ..moveTo(size.x * 0.5, size.y * 0.5 + bob)
          ..quadraticBezierTo(
            size.x * 0.5 + cos(angle) * size.x * 0.5,
            size.y * 0.5 + sin(angle) * size.y * 0.5,
            size.x * 0.5 + cos(angle + 0.3) * size.x * 0.8,
            size.y * 0.5 + sin(angle + 0.3) * size.y * 0.8,
          );
        canvas.drawPath(path, tendrilPaint);
      }
    }

    // Legs
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.78, size.x * 0.2, size.y * 0.22),
      Paint()..color = const Color(0xFF1A0A2E),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.6, size.y * 0.78, size.x * 0.2, size.y * 0.22),
      Paint()..color = const Color(0xFF1A0A2E),
    );
  }
}
