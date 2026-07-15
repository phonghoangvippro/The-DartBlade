import 'dart:ui';

import 'package:flame/components.dart';

import '../collision/hitbox.dart';
import '../combat/damage.dart';
import '../core/config/game_config.dart';
import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

class BladeWave extends PositionComponent with HasGameReference<DarkbladeGame> {
  BladeWave({
    required Vector2 position,
    required int direction,
    required double damage,
    String faction = 'player',
    double maxDistance = 380,
    Color color = const Color(0xFF7B2FF2),
    double velocityY = 0,
  }) : super(position: position, size: Vector2(34, 26), anchor: Anchor.center) {
    priority = GameConstants.priorityProjectile;
    reset(
      position: position,
      direction: direction,
      damage: damage,
      faction: faction,
      maxDistance: maxDistance,
      color: color,
      velocityY: velocityY,
    );
  }

  late int direction;
  late double damage;
  late String faction;
  late double maxDistance;
  late Color color;
  late double velocityY;

  double _travelled = 0;
  late final AttackHitbox _hitbox;

  void reset({
    required Vector2 position,
    required int direction,
    required double damage,
    required String faction,
    required double maxDistance,
    required Color color,
    required double velocityY,
  }) {
    this.position.setFrom(position);
    this.direction = direction;
    this.damage = damage;
    this.faction = faction;
    this.maxDistance = maxDistance;
    this.color = color;
    this.velocityY = velocityY;
    _travelled = 0;
  }

  @override
  Future<void> onLoad() async {
    _hitbox = AttackHitbox(
      ownerFaction: faction,
      damageProvider: (_) => DamageInfo(
        amount: damage,
        knockbackDirection: direction.toDouble(),
        knockbackForce: GameConfig.knockbackX * 0.8,
        sourcePosition: absoluteCenter.clone(),
      ),
      size: size.clone(),
    );
    add(_hitbox);
    _hitbox.activate();
  }

  @override
  void onMount() {
    super.onMount();
    if (isLoaded) {
      _hitbox.ownerFaction = faction;
      _hitbox.activate();
    }
  }

  @override
  void onRemove() {
    _hitbox.deactivate();
    game.recycleBladeWave(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final step = GameConfig.skillProjectileSpeed * dt;
    position.x += direction * step;
    if (velocityY != 0) position.y += velocityY * dt;
    _travelled += step;
    if (_travelled >= maxDistance) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.playerReady &&
        (absoluteCenter.x - game.player.absoluteCenter.x).abs() > 900) {
      return;
    }
    final glow = Paint()..color = color.withValues(alpha: 0.3);
    final core = Paint()..color = color;
    final path = Path()
      ..moveTo(direction > 0 ? 0 : size.x, 0)
      ..quadraticBezierTo(
        direction > 0 ? size.x : 0,
        size.y / 2,
        direction > 0 ? 0 : size.x,
        size.y,
      )
      ..quadraticBezierTo(
        direction > 0 ? size.x * 0.45 : size.x * 0.55,
        size.y / 2,
        direction > 0 ? 0 : size.x,
        0,
      );
    canvas.drawPath(path, glow);
    canvas.drawPath(path, core);
  }
}
