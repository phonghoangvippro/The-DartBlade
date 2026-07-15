import 'dart:ui';

import 'package:flame/components.dart';

import '../boss/boss.dart';
import '../enemy/enemy.dart';

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

class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.name,
    required this.chapterTitle,
    required this.worldSize,
    required this.playerSpawn,
    required this.platforms,
    required this.enemies,
    required this.checkpoints,
    required this.backgroundColor,
    required this.groundColor,
    required this.bgColorTop,
    required this.bgColorBottom,
    required this.atmosphere,
    this.boss,
    this.traps = const [],
    this.portalPosition,
  });

  final int id;
  final String name;
  final String chapterTitle;
  final Size worldSize;
  final Offset playerSpawn;
  final List<PlatformDef> platforms;
  final List<EnemyDef> enemies;
  final List<Offset> checkpoints;
  final Color backgroundColor;
  final Color groundColor;
  final Color bgColorTop;
  final Color bgColorBottom;
  final LevelAtmosphere atmosphere;
  final BossDef? boss;
  final List<TrapDef> traps;
  final Offset? portalPosition;

  Vector2 get playerSpawnV => Vector2(playerSpawn.dx, playerSpawn.dy);
}

enum LevelAtmosphere { rain, mist, blood, void_ }

class Levels {
  Levels._();

  static const double _g = 500;

  static final List<LevelDefinition> all = [
    villageOfAshes,
    forestOfWhispers,
    crimsonCastle,
    abyssThrone,
  ];

  static final villageOfAshes = LevelDefinition(
    id: 0,
    name: 'Village of Ashes',
    chapterTitle: 'CHƯƠNG 1: LÀNG TRO TÀN',
    worldSize: const Size(2800, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF1A1510),
    groundColor: const Color(0xFF3A2E22),
    bgColorTop: const Color(0xFF0D0806),
    bgColorBottom: const Color(0xFF2A1F14),
    atmosphere: LevelAtmosphere.rain,
    platforms: const [
      PlatformDef(0, _g, 2800, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(2800, 0, 20, 640),
      PlatformDef(350, 430, 120, 16, oneWay: true),
      PlatformDef(550, 370, 100, 16, oneWay: true),
      PlatformDef(750, 430, 100, 16, oneWay: true),
      PlatformDef(1000, 390, 120, 16, oneWay: true),
      PlatformDef(1250, 440, 100, 16, oneWay: true),
      PlatformDef(1500, 370, 130, 16, oneWay: true),
      PlatformDef(1800, 420, 100, 16, oneWay: true),
      PlatformDef(2100, 380, 140, 16, oneWay: true),
      PlatformDef(2400, 430, 100, 16, oneWay: true),
      PlatformDef(400, 390, 60, 110),
      PlatformDef(1200, 360, 50, 140),
      PlatformDef(2000, 340, 60, 160),
    ],
    enemies: [
      EnemyDef(300, _g - 50, EnemyArchetype.zombie),
      EnemyDef(600, _g - 50, EnemyArchetype.zombie),
      EnemyDef(900, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1100, _g - 50, EnemyArchetype.zombie),
      EnemyDef(1400, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1700, _g - 50, EnemyArchetype.zombie),
      EnemyDef(1950, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(2200, _g - 50, EnemyArchetype.zombie),
    ],
    traps: const [
      TrapDef(800, _g - 14, 60),
      TrapDef(1600, _g - 14, 80),
    ],
    checkpoints: const [Offset(300, _g), Offset(1400, _g)],
    boss: BossDef(2550, _g - 90, BossArchetype.fallenKnight),
    portalPosition: const Offset(2700, _g),
  );

  static final forestOfWhispers = LevelDefinition(
    id: 1,
    name: 'Forest of Whispers',
    chapterTitle: 'CHƯƠNG 2: RỪNG THÌ THẦM',
    worldSize: const Size(3200, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF12101A),
    groundColor: const Color(0xFF2D2840),
    bgColorTop: const Color(0xFF0A0814),
    bgColorBottom: const Color(0xFF1E1A30),
    atmosphere: LevelAtmosphere.mist,
    platforms: const [
      PlatformDef(0, _g, 3200, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(3200, 0, 20, 640),
      PlatformDef(400, 440, 120, 16, oneWay: true),
      PlatformDef(600, 380, 100, 16, oneWay: true),
      PlatformDef(800, 320, 120, 16, oneWay: true),
      PlatformDef(1100, 400, 100, 16, oneWay: true),
      PlatformDef(1350, 350, 130, 16, oneWay: true),
      PlatformDef(1600, 420, 100, 16, oneWay: true),
      PlatformDef(1850, 360, 120, 16, oneWay: true),
      PlatformDef(2100, 430, 100, 16, oneWay: true),
      PlatformDef(2400, 370, 130, 16, oneWay: true),
      PlatformDef(2650, 420, 100, 16, oneWay: true),
      PlatformDef(500, 350, 50, 150),
      PlatformDef(1500, 300, 60, 200),
      PlatformDef(2500, 330, 50, 170),
    ],
    enemies: [
      EnemyDef(350, _g - 50, EnemyArchetype.zombie),
      EnemyDef(650, _g - 50, EnemyArchetype.shadowWolf),
      EnemyDef(900, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1200, _g - 50, EnemyArchetype.shadowWolf),
      EnemyDef(1450, _g - 50, EnemyArchetype.spiritWitch),
      EnemyDef(1700, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1950, _g - 50, EnemyArchetype.shadowWolf),
      EnemyDef(2200, _g - 50, EnemyArchetype.spiritWitch),
      EnemyDef(2450, _g - 50, EnemyArchetype.skeleton),
    ],
    traps: const [
      TrapDef(1000, _g - 14, 70),
      TrapDef(1900, _g - 14, 60),
    ],
    checkpoints: const [Offset(300, _g), Offset(1600, _g)],
    boss: BossDef(2950, _g - 90, BossArchetype.elderTreant),
    portalPosition: const Offset(3100, _g),
  );

  static final crimsonCastle = LevelDefinition(
    id: 2,
    name: 'Crimson Castle',
    chapterTitle: 'CHƯƠNG 3: HUYẾT SẮC THÀNH',
    worldSize: const Size(3000, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF1A0E12),
    groundColor: const Color(0xFF3D1E2A),
    bgColorTop: const Color(0xFF0D0508),
    bgColorBottom: const Color(0xFF2A1218),
    atmosphere: LevelAtmosphere.blood,
    platforms: const [
      PlatformDef(0, _g, 3000, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(3000, 0, 20, 640),
      PlatformDef(350, 440, 150, 16, oneWay: true),
      PlatformDef(550, 370, 100, 16, oneWay: true),
      PlatformDef(750, 300, 120, 16, oneWay: true),
      PlatformDef(1000, 400, 100, 16, oneWay: true),
      PlatformDef(1250, 340, 130, 16, oneWay: true),
      PlatformDef(1500, 410, 100, 16, oneWay: true),
      PlatformDef(1750, 350, 120, 16, oneWay: true),
      PlatformDef(2000, 420, 100, 16, oneWay: true),
      PlatformDef(2250, 360, 130, 16, oneWay: true),
      PlatformDef(450, 350, 40, 150),
      PlatformDef(1400, 320, 40, 180),
      PlatformDef(2350, 340, 40, 160),
    ],
    enemies: [
      EnemyDef(400, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(650, _g - 50, EnemyArchetype.spiritWitch),
      EnemyDef(900, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1100, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1350, _g - 50, EnemyArchetype.spiritWitch),
      EnemyDef(1600, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1850, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(2100, _g - 50, EnemyArchetype.spiritWitch),
    ],
    traps: const [
      TrapDef(800, _g - 14, 50),
      TrapDef(1500, _g - 14, 60),
      TrapDef(2200, _g - 14, 70),
    ],
    checkpoints: const [Offset(300, _g), Offset(1700, _g)],
    boss: BossDef(2750, _g - 90, BossArchetype.bloodQueen),
    portalPosition: const Offset(2900, _g),
  );

  static final abyssThrone = LevelDefinition(
    id: 3,
    name: 'Abyss Throne',
    chapterTitle: 'CHƯƠNG CUỐI: ABYSS THRONE',
    worldSize: const Size(2400, 640),
    playerSpawn: const Offset(80, _g - 60),
    backgroundColor: const Color(0xFF0A0612),
    groundColor: const Color(0xFF1E1430),
    bgColorTop: const Color(0xFF04020A),
    bgColorBottom: const Color(0xFF140A20),
    atmosphere: LevelAtmosphere.void_,
    platforms: const [
      PlatformDef(0, _g, 2400, 140),
      PlatformDef(-20, 0, 20, 640),
      PlatformDef(2400, 0, 20, 640),
      PlatformDef(350, 430, 120, 16, oneWay: true),
      PlatformDef(600, 370, 100, 16, oneWay: true),
      PlatformDef(850, 430, 100, 16, oneWay: true),
      PlatformDef(1100, 380, 120, 16, oneWay: true),
      PlatformDef(1400, 430, 100, 16, oneWay: true),
      PlatformDef(1650, 360, 100, 16, oneWay: true),
      PlatformDef(1900, 300, 80, 16, oneWay: true),
      PlatformDef(2050, 400, 100, 16, oneWay: true),
    ],
    enemies: [
      EnemyDef(400, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(650, _g - 50, EnemyArchetype.spiritWitch),
      EnemyDef(900, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1200, _g - 50, EnemyArchetype.shadowWolf),
      EnemyDef(1500, _g - 50, EnemyArchetype.skeleton),
      EnemyDef(1750, _g - 50, EnemyArchetype.spiritWitch),
    ],
    traps: const [
      TrapDef(700, _g - 14, 60),
      TrapDef(1300, _g - 14, 80),
    ],
    checkpoints: const [Offset(300, _g)],
    boss: BossDef(2100, _g - 140, BossArchetype.kingVarkhan, isFinal: true),
    portalPosition: null,
  );
}
