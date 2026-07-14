import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../boss/boss.dart';
import '../collision/platform.dart';
import '../core/constants/game_constants.dart';
import '../enemy/enemy.dart';
import '../game/darkblade_game.dart';
import 'checkpoint.dart';
import 'level_data.dart';
import 'portal.dart';
import 'trap.dart';

/// Builds a playable level out of a [LevelDefinition] and keeps track of the
/// solid geometry for physics queries.
class Level extends Component with HasGameReference<DarkbladeGame> {
  Level(this.definition);

  final LevelDefinition definition;

  final List<Platform> platforms = [];
  Boss? boss;
  Portal? portal;

  @override
  Future<void> onLoad() async {
    // Background.
    add(_LevelBackground(definition));

    // Solid geometry.
    for (final def in definition.platforms) {
      final platform = Platform(
        position: Vector2(def.x, def.y),
        size: Vector2(def.w, def.h),
        oneWay: def.oneWay,
        color: def.oneWay
            ? definition.groundColor.withValues(alpha: 0.85)
            : definition.groundColor,
      );
      platforms.add(platform);
      add(platform);
    }

    // Traps.
    for (final t in definition.traps) {
      add(SpikeTrap(
          position: Vector2(t.x, t.y), width: t.w));
    }

    // Checkpoints.
    for (final c in definition.checkpoints) {
      add(Checkpoint(position: Vector2(c.dx, c.dy)));
    }

    // Enemies.
    for (final e in definition.enemies) {
      final enemy = Enemy(
        position: Vector2(e.x, e.y),
        archetype: e.archetype,
      );
      enemy.platformsProvider = () => platforms;
      add(enemy);
    }

    // Boss.
    final bossDef = definition.boss;
    if (bossDef != null) {
      boss = Boss(
        position: Vector2(bossDef.x, bossDef.y),
        archetype: bossDef.archetype,
        isFinalBoss: bossDef.isFinal,
      );
      boss!.platformsProvider = () => platforms;
      add(boss!);
    }

    // Portal to next map.
    final portalPos = definition.portalPosition;
    if (portalPos != null) {
      portal = Portal(position: Vector2(portalPos.dx, portalPos.dy));
      // Portal opens immediately on levels without a boss.
      portal!.unlocked = definition.boss == null;
      add(portal!);
    }
  }
}

/// Simple parallax-ish decorative backdrop drawn procedurally.
class _LevelBackground extends PositionComponent {
  _LevelBackground(this.definition)
      : super(
          position: Vector2.zero(),
          size: Vector2(
              definition.worldSize.width, definition.worldSize.height),
        ) {
    priority = GameConstants.priorityBackground;
  }

  final LevelDefinition definition;
  final Random _rng = Random(7);
  late final List<Rect> _pillars = List.generate(24, (i) {
    final w = 30.0 + _rng.nextDouble() * 60;
    final h = 120.0 + _rng.nextDouble() * 240;
    final x = _rng.nextDouble() * definition.worldSize.width;
    return Rect.fromLTWH(x, definition.worldSize.height - 140 - h, w, h);
  });

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = definition.backgroundColor,
    );
    final pillarPaint = Paint()
      ..color = definition.groundColor.withValues(alpha: 0.35);
    for (final rect in _pillars) {
      canvas.drawRect(rect, pillarPaint);
    }
  }
}
