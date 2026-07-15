import 'dart:ui';

import 'package:flame/components.dart';

import '../collision/hitbox.dart';
import '../collision/hurtbox.dart';
import '../combat/combo_tracker.dart';
import '../combat/damage.dart';
import '../core/config/game_config.dart';
import '../core/constants/game_constants.dart';
import '../core/services/audio_service.dart';
import '../entities/character.dart';
import '../game/darkblade_game.dart';
import 'player_animation.dart';
import 'player_controller.dart';
import 'player_state.dart';
import 'player_stats.dart';

/// The player character: a swordsman wielding the Darkblade.
///
/// Implements the full state machine from the plan:
/// Idle / Run / Jump / Fall / Attack1-3 / Dash / Block / Hurt / Dead
/// with combo timer, dash i-frames + cooldown, stamina & mana costs.
class Player extends Character with HasGameReference<DarkbladeGame> {
  Player({required super.position})
    : super(size: Vector2(34, 52), maxHp: GameConfig.playerMaxHp) {
    priority = GameConstants.priorityPlayer;
  }

  final PlayerController controller = PlayerController();
  final PlayerStats stats = PlayerStats();
  final ComboTracker combo = ComboTracker();
  final DamageCalculator _damageCalc = DamageCalculator();
  final PlayerAnimator _animator = PlayerAnimator();

  PlayerState state = PlayerState.idle;

  // Timers.
  double _stateTimer = 0;
  double _dashCooldown = 0;
  double _skillCooldown = 0;
  double _coyoteTimer = 0;

  double get dashCooldownRatio =>
      (_dashCooldown / GameConfig.dashCooldown).clamp(0.0, 1.0);
  double get skillCooldownRatio =>
      (_skillCooldown / GameConfig.skillCooldown).clamp(0.0, 1.0);

  late final AttackHitbox _meleeHitbox;
  late final Hurtbox _hurtbox;

  Vector2 respawnPoint = Vector2.zero();
  bool unlockDash = true;

  @override
  String get faction => 'player';

  @override
  Future<void> onLoad() async {
    respawnPoint = position.clone();

    _hurtbox = Hurtbox(
      owner: this,
      position: Vector2(4, 4),
      size: Vector2(size.x - 8, size.y - 8),
    );
    add(_hurtbox);

    _meleeHitbox = AttackHitbox(
      ownerFaction: faction,
      damageProvider: _computeMeleeDamage,
      position: Vector2(size.x, (size.y - GameConfig.meleeRangeY) / 2),
      size: Vector2(GameConfig.meleeRangeX, GameConfig.meleeRangeY),
    );
    add(_meleeHitbox);
  }

  DamageInfo _computeMeleeDamage(Damageable target) {
    final result = _damageCalc.calculate(
      attack: stats.attack,
      skillMultiplier: combo.multiplier,
      defense: 0, // target defense is subtracted by the target itself
    );
    game.onPlayerDealtDamage(result);
    return DamageInfo(
      amount: result.amount,
      knockbackDirection: facing.toDouble(),
      isCritical: result.isCritical,
    );
  }

  // ------------------------------------------------------------------ update
  @override
  void update(double dt) {
    if (game.phase != GamePhase.playing && game.phase != GamePhase.gameOver) {
      return;
    }
    super.update(dt);
    if (state == PlayerState.dead) {
      applyPhysics(dt);
      return;
    }

    combo.update(dt);
    stats.regenerate(dt);
    if (_dashCooldown > 0) _dashCooldown -= dt;
    if (_skillCooldown > 0) _skillCooldown -= dt;
    _stateTimer += dt;

    controller.resolveFrame(); // merge keyboard + touch into intents
    _handleInput();
    _updateState(dt);
    _updateMeleeHitbox();
    applyPhysics(dt);
    _postPhysicsState();

    controller.clearOneShots();
  }

  void _handleInput() {
    final c = controller;

    if (state.locksMovement) return;

    // Facing + horizontal movement.
    if (c.moveDirection != 0 && state != PlayerState.block) {
      facing = c.moveDirection > 0 ? 1 : -1;
      velocity.x = c.moveDirection * GameConfig.runSpeed;
    } else {
      velocity.x = 0;
    }

    // Coyote-time jump (FR-001).
    if (isOnGround) _coyoteTimer = GameConfig.coyoteTime;
    if (c.jumpPressed && _coyoteTimer > 0 && state != PlayerState.block) {
      velocity.y = GameConfig.jumpVelocity;
      _coyoteTimer = 0;
      AudioService.instance.playSfx('jump.wav');
    }

    // Attack (FR-003, FR-004).
    if (c.attackPressed && stats.spendStamina(GameConfig.attackStaminaCost)) {
      _startAttack();
      return;
    }

    // Dash (FR-005).
    if (c.dashPressed &&
        _dashCooldown <= 0 &&
        stats.spendStamina(GameConfig.dashStaminaCost)) {
      _startDash();
      return;
    }

    // Skill (FR-018).
    if (c.skillPressed &&
        _skillCooldown <= 0 &&
        stats.spendMana(GameConfig.skillManaCost)) {
      _castBladeWave();
    }

    // Potion (FR-030).
    if (c.potionPressed) {
      game.useEquippedPotion();
    }

    // Block (FR-015).
    if (c.blockHeld && isOnGround) {
      _setState(PlayerState.block);
      velocity.x = 0;
    } else if (state == PlayerState.block) {
      _setState(PlayerState.idle);
    }
  }

  void _startAttack() {
    final step = combo.registerAttack();
    _setState(switch (step) {
      1 => PlayerState.attack1,
      2 => PlayerState.attack2,
      _ => PlayerState.attack3,
    });
    velocity.x = facing * 40; // small forward step
    AudioService.instance.playSfx('sword_swing.wav');
  }

  void _startDash() {
    _setState(PlayerState.dash);
    _dashCooldown = GameConfig.dashCooldown;
    invincibleTimer = GameConfig.dashDuration; // i-frames
    velocity.x = facing * GameConfig.dashSpeed;
    velocity.y = 0;
    AudioService.instance.playSfx('dash.wav');
  }

  void _castBladeWave() {
    _skillCooldown = GameConfig.skillCooldown;
    final result = _damageCalc.calculate(
      attack: stats.attack,
      skillMultiplier: GameConfig.skillMultiplier,
    );
    game.spawnBladeWave(
      position: absoluteCenter + Vector2(facing * 24, -4),
      direction: facing,
      damage: result.amount,
    );
    AudioService.instance.playSfx('skill.wav');
  }

  void _updateState(double dt) {
    switch (state) {
      case PlayerState.attack1:
      case PlayerState.attack2:
      case PlayerState.attack3:
        // Hit window (FR-010): active only between hitStart..hitEnd.
        final active =
            _stateTimer >= GameConfig.attackHitStart &&
            _stateTimer <= GameConfig.attackHitEnd;
        if (active && !_meleeHitbox.isActive) _meleeHitbox.activate();
        if (!active && _meleeHitbox.isActive) _meleeHitbox.deactivate();
        // Friction during swing.
        velocity.x *= 0.86;
        if (_stateTimer >= GameConfig.attackDuration) {
          _meleeHitbox.deactivate();
          _setState(PlayerState.idle);
        }
        break;
      case PlayerState.dash:
        gravityEnabled = false;
        if (_stateTimer >= GameConfig.dashDuration) {
          gravityEnabled = true;
          velocity.x = 0;
          _setState(PlayerState.idle);
        }
        break;
      case PlayerState.hurt:
        if (_stateTimer >= 0.3) _setState(PlayerState.idle);
        break;
      default:
        break;
    }
    if (_coyoteTimer > 0) _coyoteTimer -= dt;
  }

  /// Resolve locomotion states after physics so ground info is fresh.
  void _postPhysicsState() {
    if (state.locksMovement || state == PlayerState.block) return;
    if (!isOnGround) {
      _setState(
        velocity.y < 0 ? PlayerState.jump : PlayerState.fall,
        keepTimer: true,
      );
    } else if (velocity.x.abs() > 5) {
      _setState(PlayerState.run, keepTimer: true);
    } else {
      _setState(PlayerState.idle, keepTimer: true);
    }
  }

  void _updateMeleeHitbox() {
    // Mirror the hitbox to the facing side.
    _meleeHitbox.position = facing > 0
        ? Vector2(size.x, (size.y - GameConfig.meleeRangeY) / 2)
        : Vector2(
            -GameConfig.meleeRangeX,
            (size.y - GameConfig.meleeRangeY) / 2,
          );
  }

  void _setState(PlayerState next, {bool keepTimer = false}) {
    if (state == next) return;
    state = next;
    if (!keepTimer) _stateTimer = 0;
  }

  // ------------------------------------------------------------------ damage
  @override
  void receiveDamage(DamageInfo info) {
    if (isDead || isInvincible) return;

    final sourcePosition = info.sourcePosition;
    final facingIncomingHit = sourcePosition != null
        ? (sourcePosition.x >= absoluteCenter.x ? facing > 0 : facing < 0)
        : (info.knockbackDirection > 0 ? facing < 0 : facing > 0);
    final blocking =
        state == PlayerState.block &&
        // Must face the attack to block it.
        facingIncomingHit;

    if (blocking) {
      stats.spendStamina(info.amount * GameConfig.blockStaminaFactor);
      AudioService.instance.playSfx('block.wav');
      invincibleTimer = 0.08;
      return;
    }

    var amount = info.amount - stats.defense;
    if (amount < 1) amount = 1;
    health.damage(amount);
    game.onPlayerDamaged(amount);

    if (health.isDead) {
      onDeath();
      return;
    }

    invincibleTimer = GameConfig.hurtInvincibleTime;
    if (!blocking) {
      applyKnockback(info);
      _setState(PlayerState.hurt);
      AudioService.instance.playSfx('hurt.wav');
    }
  }

  @override
  void onDeath() {
    _setState(PlayerState.dead);
    _meleeHitbox.deactivate();
    velocity.setZero();
    // Souls-like penalty: lose part of your souls (FR-007).
    stats.souls = (stats.souls * GameConfig.soulsLossOnDeathFactor).floor();
    AudioService.instance.playSfx('death.wav');
    game.onPlayerDied();
  }

  /// Respawn at last checkpoint (FR-008).
  void respawn() {
    position = respawnPoint.clone();
    health.refill();
    stats.stamina = stats.maxStamina;
    stats.mana = stats.maxMana;
    velocity.setZero();
    invincibleTimer = 1.0;
    gravityEnabled = true;
    _setState(PlayerState.idle);
  }

  // ------------------------------------------------------------------ render
  @override
  void render(Canvas canvas) {
    final attackProgress = state.isAttacking
        ? (_stateTimer / GameConfig.attackDuration).clamp(0.0, 1.0)
        : 0.0;
    _animator.render(
      canvas,
      size.toSize(),
      state,
      facing,
      animationTime,
      invincible: isInvincible && state != PlayerState.dash,
      attackProgress: attackProgress,
    );
  }
}
