import 'dart:ui';

import 'package:flame/components.dart';

import '../boss/boss.dart';
import '../enemy/enemy.dart';

/// Declarative spawn entries -------------------------------------------------

class PlatformDef {
  const PlatformDef(this.x, this.y, this.w, this.h, {this.oneWay = false});
  final double x, y, w, h;
  final bool oneWay;
}

class EnemyDef {
  const EnemyDef(this.x, this.y, this.archetype);
  final double x, y;
  final EnemyArchetype archetype;
}

class BossDef {
  const BossDef(this.x, this.y, this.archetype, {this.isFinal = false});
  final double x, y;
  final BossArchetype archetype;
  final bool isFinal;
}

class TrapDef {
  const TrapDef(this.x, this.y, this.w);
  final double x, y, w;
}

/// Full description of one map (plan section 12).
class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.name,
    required this.worldSize,
    required this.playerSpawn,
    required this.platforms,
    required this.enemies,
    required this.checkpoints,
    required this.backgroundColor,
    required this.groundColor,
    this.boss,
    this.traps = const [],
    this.portalPosition,
  });

  final int id;
  final String name;
  final Size worldSize;
  final Offset playerSpawn;
  final List<PlatformDef> platforms;
  final List<EnemyDef> enemies;
  final List<Offset> checkpoints;
  final Color backgroundColor;
  final Color groundColor;
  final BossDef? boss;
  final List<TrapDef> traps;
  final Offset? portalPosition;

  Vector2 get playerSpawnV => Vector2(playerSpawn.dx, playerSpawn.dy);
}

/// The five maps of The Darkblade.
class Levels {
  Levels._();

  static const double _g = 500; // common ground level (y of floor top)

  static final List<LevelDefinition> all = [
    forgottenForest,
    darkCave,
    ancientTemple,
    frozenCastle,
    darkThrone,
  ];

  // ------------------------------------------------- Map 1: Forgotten Forest
  static final forgottenForest = LevelDefinition(
    id: 0,
    name: 'Forgotten Forest',
    worldSize: const Size(2400, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF15211A),
    groundColor: const Color(0xFF2C3A2C),
    platforms: const [
      PlatformDef(0, _g, 2400, 140), // floor
      PlatformDef(-20, 0, 20, 640), // left wall
      PlatformDef(2400, 0, 20, 640), // right wall
      PlatformDef(380, 420, 120, 16, oneWay: true),
      PlatformDef(560, 350, 120, 16, oneWay: true),
      PlatformDef(760, 420, 140, 16, oneWay: true),
      PlatformDef(1050, 400, 100, 16, oneWay: true),
      PlatformDef(1350, 430, 160, 16, oneWay: true),
      PlatformDef(1600, 360, 120, 16, oneWay: true),
    ],
    enemies: [
      const EnemyDef(500, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(850, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(1200, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(1500, _g - 50, EnemyArchetype.caveBat),
      const EnemyDef(1750, _g - 50, EnemyArchetype.hollowSoldier),
    ],
    traps: const [TrapDef(950, _g - 14, 60)],
    checkpoints: const [Offset(320, _g), Offset(1450, _g)],
    boss: const BossDef(2050, _g - 90, BossArchetype.forestGuardian),
    portalPosition: const Offset(2320, _g),
  );

  // ------------------------------------------------------ Map 2: Dark Cave
  static final darkCave = LevelDefinition(
    id: 1,
    name: 'Dark Cave',
    worldSize: const Size(2600, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF14121A),
    groundColor: const Color(0xFF2E2A38),
    platforms: const [
      PlatformDef(0, _g, 2600, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(2600, 0, 20, 640),
      PlatformDef(300, 430, 100, 16, oneWay: true),
      PlatformDef(520, 370, 100, 16, oneWay: true),
      PlatformDef(720, 300, 120, 16, oneWay: true),
      PlatformDef(980, 380, 90, 16, oneWay: true),
      PlatformDef(1250, 420, 140, 16, oneWay: true),
      PlatformDef(1550, 340, 110, 16, oneWay: true),
      PlatformDef(1850, 410, 130, 16, oneWay: true),
      // ceiling stalactites area
      PlatformDef(1100, 0, 400, 60),
    ],
    enemies: [
      const EnemyDef(450, _g - 50, EnemyArchetype.caveBat),
      const EnemyDef(700, _g - 50, EnemyArchetype.caveBat),
      const EnemyDef(1000, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(1300, _g - 50, EnemyArchetype.caveBat),
      const EnemyDef(1600, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(1900, _g - 50, EnemyArchetype.cursedKnight),
    ],
    traps: const [
      TrapDef(850, _g - 14, 80),
      TrapDef(1450, _g - 14, 60),
    ],
    checkpoints: const [Offset(250, _g), Offset(1500, _g)],
    portalPosition: const Offset(2520, _g),
  );

  // -------------------------------------------------- Map 3: Ancient Temple
  static final ancientTemple = LevelDefinition(
    id: 2,
    name: 'Ancient Temple',
    worldSize: const Size(2600, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF1E1A14),
    groundColor: const Color(0xFF3D3627),
    platforms: const [
      PlatformDef(0, _g, 2600, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(2600, 0, 20, 640),
      // temple steps
      PlatformDef(400, 450, 120, 50),
      PlatformDef(520, 400, 120, 100),
      PlatformDef(640, 350, 200, 150),
      PlatformDef(1100, 420, 100, 16, oneWay: true),
      PlatformDef(1320, 360, 100, 16, oneWay: true),
      PlatformDef(1540, 420, 100, 16, oneWay: true),
      PlatformDef(1800, 380, 160, 16, oneWay: true),
    ],
    enemies: [
      const EnemyDef(500, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(750, 300, EnemyArchetype.cursedKnight),
      const EnemyDef(1150, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(1400, _g - 50, EnemyArchetype.cursedKnight),
      const EnemyDef(1700, _g - 50, EnemyArchetype.caveBat),
      const EnemyDef(1950, _g - 50, EnemyArchetype.cursedKnight),
    ],
    traps: const [TrapDef(1000, _g - 14, 90)],
    checkpoints: const [Offset(300, _g), Offset(1600, _g)],
    portalPosition: const Offset(2520, _g),
  );

  // -------------------------------------------------- Map 4: Frozen Castle
  static final frozenCastle = LevelDefinition(
    id: 3,
    name: 'Frozen Castle',
    worldSize: const Size(2600, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF13202B),
    groundColor: const Color(0xFF2C3D4D),
    platforms: const [
      PlatformDef(0, _g, 2600, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(2600, 0, 20, 640),
      // battlements
      PlatformDef(350, 430, 90, 70),
      PlatformDef(560, 380, 90, 120),
      PlatformDef(780, 330, 90, 170),
      PlatformDef(1050, 400, 120, 16, oneWay: true),
      PlatformDef(1300, 330, 120, 16, oneWay: true),
      PlatformDef(1560, 400, 120, 16, oneWay: true),
      PlatformDef(1850, 350, 200, 16, oneWay: true),
    ],
    enemies: [
      const EnemyDef(450, _g - 50, EnemyArchetype.cursedKnight),
      const EnemyDef(820, 260, EnemyArchetype.caveBat),
      const EnemyDef(1100, _g - 50, EnemyArchetype.cursedKnight),
      const EnemyDef(1400, _g - 50, EnemyArchetype.hollowSoldier),
      const EnemyDef(1650, _g - 50, EnemyArchetype.cursedKnight),
      const EnemyDef(1950, _g - 50, EnemyArchetype.cursedKnight),
    ],
    traps: const [
      TrapDef(950, _g - 14, 70),
      TrapDef(1500, _g - 14, 50),
      TrapDef(2100, _g - 14, 60),
    ],
    checkpoints: const [Offset(280, _g), Offset(1700, _g)],
    portalPosition: const Offset(2520, _g),
  );

  // --------------------------------------------------- Map 5: Dark Throne
  static final darkThrone = LevelDefinition(
    id: 4,
    name: 'Dark Throne',
    worldSize: const Size(1800, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF190E1E),
    groundColor: const Color(0xFF32243D),
    platforms: const [
      PlatformDef(0, _g, 1800, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(1800, 0, 20, 640),
      PlatformDef(350, 420, 120, 16, oneWay: true),
      PlatformDef(1330, 420, 120, 16, oneWay: true),
    ],
    enemies: [
      const EnemyDef(400, _g - 50, EnemyArchetype.cursedKnight),
      const EnemyDef(600, _g - 50, EnemyArchetype.cursedKnight),
    ],
    checkpoints: const [Offset(250, _g)],
    boss: const BossDef(1250, _g - 90, BossArchetype.darkKing, isFinal: true),
  );
}
