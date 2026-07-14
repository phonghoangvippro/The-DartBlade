import 'dart:ui';

import 'package:flame/components.dart';

import '../collision/hitbox.dart';
import '../combat/damage.dart';
import '../core/config/game_config.dart';
import '../core/constants/game_constants.dart';

/// The player's ranged skill (FR-018): a crescent of dark energy that flies
/// horizontally and damages the first enemy it touches.
class BladeWave extends PositionComponent {
  BladeWave({
    required Vector2 position,
    required this.direction,
    required this.damage,
    this.faction = 'player',
    this.maxDistance = 380,
  }) : super(
          position: position,
          size: Vector2(34, 26),
          anchor: Anchor.center,
        ) {
    priority = GameConstants.priorityProjectile;
  }

  final int direction;
  final double damage;
  final String faction;
  final double maxDistance;

  double _travelled = 0;
  late final AttackHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    _hitbox = AttackHitbox(
      ownerFaction: faction,
      damageProvider: (_) => DamageInfo(
        amount: damage,
        knockbackDirection: direction.toDouble(),
        knockbackForce: GameConfig.knockbackX * 0.8,
      ),
      size: size.clone(),
    );
    add(_hitbox);
    _hitbox.activate();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final step = GameConfig.skillProjectileSpeed * dt;
    position.x += direction * step;
    _travelled += step;
    if (_travelled >= maxDistance) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final glow = Paint()
      ..color = const Color(0x807B2FF2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()..color = const Color(0xFFB388FF);
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
