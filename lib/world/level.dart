import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../boss/boss.dart';
import '../collision/platform.dart';
import '../core/constants/game_constants.dart';
import '../effects/particle_system.dart';
import '../enemy/enemy.dart';
import '../game/darkblade_game.dart';
import 'checkpoint.dart';
import 'level_data.dart';
import 'portal.dart';
import 'trap.dart';

class Level extends Component with HasGameReference<DarkbladeGame> {
  Level(this.definition);

  final LevelDefinition definition;

  final List<Platform> platforms = [];
  Boss? boss;
  Portal? portal;

  @override
  Future<void> onLoad() async {
    add(_LevelBackground(definition));
    add(_AtmosphereEffect(definition));

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

    for (final t in definition.traps) {
      add(SpikeTrap(position: Vector2(t.x, t.y), width: t.w));
    }

    for (final c in definition.checkpoints) {
      add(Checkpoint(position: Vector2(c.dx, c.dy)));
    }

    for (final e in definition.enemies) {
      final enemy = Enemy(position: Vector2(e.x, e.y), archetype: e.archetype);
      enemy.platformsProvider = () => platforms;
      add(enemy);
    }

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

    final portalPos = definition.portalPosition;
    if (portalPos != null) {
      portal = Portal(position: Vector2(portalPos.dx, portalPos.dy));
      portal!.unlocked = definition.boss == null;
      add(portal!);
    }
  }
}

class _LevelBackground extends PositionComponent {
  _LevelBackground(this.definition)
    : super(
        position: Vector2.zero(),
        size: Vector2(definition.worldSize.width, definition.worldSize.height),
      ) {
    priority = GameConstants.priorityBackground;
  }

  final LevelDefinition definition;
  Picture? _background;

  @override
  Future<void> onLoad() async {
    final recorder = PictureRecorder();
    _paintBackground(Canvas(recorder), Random(7));
    _background = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final background = _background;
    if (background != null) canvas.drawPicture(background);
  }

  void _paintBackground(Canvas canvas, Random rng) {
    final w = size.x;
    final h = size.y;

    // Gradient background
    final gradient = Paint()
      ..shader = Gradient.linear(Offset(0, 0), Offset(0, h), [
        definition.bgColorTop,
        definition.bgColorBottom,
      ]);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradient);

    // Atmosphere-specific decorations
    switch (definition.atmosphere) {
      case LevelAtmosphere.rain:
        _renderVillageBackground(canvas, w, h, rng);
      case LevelAtmosphere.mist:
        _renderForestBackground(canvas, w, h, rng);
      case LevelAtmosphere.blood:
        _renderCastleBackground(canvas, w, h, rng);
      case LevelAtmosphere.void_:
        _renderAbyssBackground(canvas, w, h, rng);
    }

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, h - 140, w, 140),
      Paint()..color = definition.groundColor,
    );
  }

  void _renderVillageBackground(Canvas canvas, double w, double h, Random rng) {
    // Burnt houses silhouettes
    final housePaint = Paint()..color = const Color(0xFF1A1510);
    for (var i = 0; i < 8; i++) {
      final x = 100.0 + i * 320 + rng.nextDouble() * 100;
      final houseH = 80 + rng.nextDouble() * 100;
      canvas.drawRect(
        Rect.fromLTWH(x, h - 140 - houseH, 60 + rng.nextDouble() * 40, houseH),
        housePaint,
      );
      // Roof
      final roofPath = Path()
        ..moveTo(x - 10, h - 140 - houseH)
        ..lineTo(x + 35, h - 140 - houseH - 40)
        ..lineTo(x + 80, h - 140 - houseH)
        ..close();
      canvas.drawPath(roofPath, housePaint);
    }

    // Distant mountains
    final mountainPaint = Paint()..color = const Color(0xFF0D0806);
    final mountainPath = Path()
      ..moveTo(0, h - 140)
      ..quadraticBezierTo(w * 0.25, h - 300, w * 0.5, h - 180)
      ..quadraticBezierTo(w * 0.75, h - 350, w, h - 200)
      ..lineTo(w, h - 140)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    // Smoke columns
    final smokePaint = Paint()
      ..color = const Color(0x2A2A2A2A)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);
    for (var i = 0; i < 4; i++) {
      final x = w * (0.2 + i * 0.25);
      canvas.drawCircle(Offset(x, h - 300 - i * 20), 20 + i * 10, smokePaint);
    }
  }

  void _renderForestBackground(Canvas canvas, double w, double h, Random rng) {
    // Giant tree silhouettes
    final treePaint = Paint()..color = const Color(0xFF0A0814);
    for (var i = 0; i < 12; i++) {
      final x = i * (w / 10) + rng.nextDouble() * 60;
      final treeH = 200 + rng.nextDouble() * 180;

      // Trunk
      canvas.drawRect(
        Rect.fromLTWH(x - 8, h - 140 - treeH, 16, treeH),
        treePaint,
      );

      // Canopy
      canvas.drawCircle(
        Offset(x, h - 140 - treeH),
        40 + rng.nextDouble() * 30,
        treePaint,
      );
      canvas.drawCircle(
        Offset(x - 20, h - 140 - treeH + 30),
        30 + rng.nextDouble() * 20,
        treePaint,
      );
      canvas.drawCircle(
        Offset(x + 20, h - 140 - treeH + 30),
        30 + rng.nextDouble() * 20,
        treePaint,
      );
    }

    // Glowing eyes in the dark
    final eyePaint = Paint()
      ..color = const Color(0x22AA44FF)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, h - 250.0 - rng.nextDouble() * 100.0),
        4.0,
        eyePaint,
      );
    }
  }

  void _renderCastleBackground(Canvas canvas, double w, double h, Random rng) {
    // Castle walls
    final wallPaint = Paint()..color = const Color(0xFF0D0508);
    canvas.drawRect(Rect.fromLTWH(0, h - 400, w, 260), wallPaint);

    // Battlements
    for (var i = 0; i < 20; i++) {
      final x = (i * 60 + 10).toDouble();
      canvas.drawRect(Rect.fromLTWH(x, h - 420.0, 40.0, 20.0), wallPaint);
    }

    // Gothic windows (glowing)
    final windowPaint = Paint()
      ..color = const Color(0x33FF4422)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
    for (var i = 0; i < 8; i++) {
      final x = 80 + i * 280 + rng.nextDouble() * 60;
      final archPath = Path()
        ..moveTo(x, h - 320)
        ..quadraticBezierTo(x + 15, h - 370, x + 30, h - 320)
        ..lineTo(x + 30, h - 280)
        ..lineTo(x, h - 280)
        ..close();
      canvas.drawPath(archPath, windowPaint);
    }

    // Blood drips on walls
    final bloodPaint = Paint()
      ..color = const Color(0x1A8B0000)
      ..strokeWidth = 3;
    for (var i = 0; i < 10; i++) {
      final x = rng.nextDouble() * w;
      canvas.drawLine(
        Offset(x, h - 350.0 + rng.nextDouble() * 100.0),
        Offset(x, h - 300.0 + rng.nextDouble() * 80.0),
        bloodPaint,
      );
    }
  }

  void _renderAbyssBackground(Canvas canvas, double w, double h, Random rng) {
    // Void background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF04020A),
    );

    // Floating rocks
    final rockPaint = Paint()..color = const Color(0xFF0E0A18);
    for (var i = 0; i < 10; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * (h - 200);
      final rw = 30 + rng.nextDouble() * 60;
      final rh = 20 + rng.nextDouble() * 30;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, rw, rh),
          const Radius.circular(4),
        ),
        rockPaint,
      );
    }

    // Red lava glow at bottom
    final lavaPaint = Paint()
      ..color = const Color(0x22FF2200)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawRect(Rect.fromLTWH(0, h - 160, w, 20), lavaPaint);

    // Cracked moon
    final moonPaint = Paint()..color = const Color(0xFF1A1020);
    canvas.drawCircle(Offset(w * 0.7, h * 0.15), 40, moonPaint);
    final crackPath = Path()
      ..moveTo(w * 0.7, h * 0.12)
      ..lineTo(w * 0.73, h * 0.18)
      ..lineTo(w * 0.68, h * 0.22);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = const Color(0xFFFF4400)
        ..strokeWidth = 2,
    );
  }
}

class _AtmosphereEffect extends Component {
  final LevelDefinition definition;
  Component? _effect;

  _AtmosphereEffect(this.definition);

  @override
  void onMount() {
    super.onMount();
    _spawnEffect();
  }

  void _spawnEffect() {
    final w = definition.worldSize.width;
    final h = definition.worldSize.height;

    switch (definition.atmosphere) {
      case LevelAtmosphere.rain:
        _effect = RainEffect(w, h);
      case LevelAtmosphere.mist:
        _effect = DarkMistEffect(w, h, const Color(0xFF2A2040));
      case LevelAtmosphere.blood:
        _effect = DarkMistEffect(w, h, const Color(0xFF1A0A0A));
      case LevelAtmosphere.void_:
        _effect = AshFallEffect(w, h);
    }

    if (_effect != null) add(_effect!);
  }
}
