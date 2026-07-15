import 'package:flame/components.dart';

import 'enemy_state.dart';

/// Context handed to the AI every tick.
class AiContext {
  const AiContext({
    required this.distanceToPlayer,
    required this.playerAlive,
    required this.dt,
  });

  final double distanceToPlayer;
  final bool playerAlive;
  final double dt;
}

/// Decisions the FSM outputs; the enemy component executes them.
abstract class EnemyBrainHost {
  Vector2 get position;
  int get facing;
  set facing(int value);
  void moveHorizontal(double speed);
  void stopHorizontal();
  void performAttack();
  double get playerDirection; // -1 or 1 towards the player
}

/// Finite State Machine implementing:
/// Idle -> Patrol -> (Detect) -> Chase -> Attack -> Recover -> Chase/Patrol
/// with tunable detect/attack ranges (defaults per plan: 150px / 40px).
class EnemyAi {
  EnemyAi({
    required this.host,
    required this.detectRange,
    required this.attackRange,
    required this.patrolSpeed,
    required this.chaseSpeed,
    required this.attackDuration,
    required this.recoverDuration,
    this.patrolDistance = 90,
    this.idleDuration = 1.2,
  });

  final EnemyBrainHost host;
  final double detectRange;
  final double attackRange;
  final double patrolSpeed;
  final double chaseSpeed;
  final double attackDuration;
  final double recoverDuration;
  final double patrolDistance;
  final double idleDuration;

  EnemyState state = EnemyState.idle;
  double stateTimer = 0;
  double _patrolOriginX = double.nan;

  void forceState(EnemyState next) {
    state = next;
    stateTimer = 0;
  }

  void update(AiContext ctx) {
    if (state == EnemyState.dead) return;
    _patrolOriginX = _patrolOriginX.isNaN ? host.position.x : _patrolOriginX;
    stateTimer += ctx.dt;

    switch (state) {
      case EnemyState.idle:
        host.stopHorizontal();
        if (_playerDetected(ctx)) {
          forceState(EnemyState.chase);
        } else if (stateTimer >= idleDuration) {
          forceState(EnemyState.patrol);
        }
        break;

      case EnemyState.patrol:
        // Walk back and forth around the patrol origin (FR-019).
        host.moveHorizontal(host.facing * patrolSpeed);
        final offset = host.position.x - _patrolOriginX;
        if (offset.abs() > patrolDistance) {
          host.facing = offset > 0 ? -1 : 1;
        }
        if (_playerDetected(ctx)) forceState(EnemyState.chase);
        if (stateTimer > 4) forceState(EnemyState.idle);
        break;

      case EnemyState.chase:
        // FR-021: run towards the player.
        if (!ctx.playerAlive || ctx.distanceToPlayer > detectRange * 1.6) {
          forceState(EnemyState.patrol);
          break;
        }
        host.facing = host.playerDirection > 0 ? 1 : -1;
        if (ctx.distanceToPlayer <= attackRange) {
          host.stopHorizontal();
          host.performAttack();
          forceState(EnemyState.attack);
        } else {
          host.moveHorizontal(host.facing * chaseSpeed);
        }
        break;

      case EnemyState.attack:
        host.stopHorizontal();
        if (stateTimer >= attackDuration) {
          forceState(EnemyState.recover);
        }
        break;

      case EnemyState.recover:
        host.stopHorizontal();
        if (stateTimer >= recoverDuration) {
          forceState(
            ctx.playerAlive && ctx.distanceToPlayer <= detectRange
                ? EnemyState.chase
                : EnemyState.patrol,
          );
        }
        break;

      case EnemyState.hurt:
        if (stateTimer >= 0.35) {
          forceState(EnemyState.chase);
        }
        break;

      case EnemyState.dead:
        break;
    }
  }

  bool _playerDetected(AiContext ctx) =>
      ctx.playerAlive && ctx.distanceToPlayer <= detectRange; // FR-020
}
