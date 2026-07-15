import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants/game_constants.dart';

/// Floating combat text that drifts upwards and fades out.
class DamageNumber extends TextComponent {
  DamageNumber({
    required Vector2 position,
    required double amount,
    bool critical = false,
  }) : super(
         position: position,
         anchor: Anchor.center,
         text: critical
             ? '${amount.toStringAsFixed(0)}!'
             : amount.toStringAsFixed(0),
         textRenderer: TextPaint(
           style: TextStyle(
             fontSize: critical ? 16 : 12,
             fontWeight: FontWeight.bold,
             color: critical
                 ? const Color(0xFFFFD54F)
                 : const Color(0xFFF1F1F1),
             shadows: const [Shadow(blurRadius: 2, offset: Offset(1, 1))],
           ),
         ),
       ) {
    priority = GameConstants.priorityFx;
  }

  double _life = 0.7;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 40 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }
}
