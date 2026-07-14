import 'dart:math';
import 'dart:ui';

import 'player_state.dart';

/// Procedural placeholder renderer for the player.
///
/// Renders a stylised dark knight with a glowing blade directly on the
/// canvas so the whole game runs before any sprite sheets are produced.
/// Swap this class for a `SpriteAnimationGroupComponent` once art exists -
/// the state machine already exposes everything needed
/// (state + facing + animationTime).
class PlayerAnimator {
  static const Color _bodyColor = Color(0xFF2B2B3A);
  static const Color _armorColor = Color(0xFF44445C);
  static const Color _bladeColor = Color(0xFF7B2FF2);
  static const Color _bladeGlow = Color(0x557B2FF2);
  static const Color _hurtColor = Color(0xFFB03A48);

  /// Draws the player inside a [size] box. Canvas origin = top-left of body.
  void render(
    Canvas canvas,
    Size size,
    PlayerState state,
    int facing,
    double t, {
    bool invincible = false,
    double attackProgress = 0,
  }) {
    canvas.save();
    // Flip horizontally around the centre when facing left.
    if (facing < 0) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    // Invincibility flicker.
    if (invincible && (t * 20).floor().isEven) {
      canvas.restore();
      return;
    }

    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()
      ..color = state == PlayerState.hurt ? _hurtColor : _bodyColor;
    final armorPaint = Paint()..color = _armorColor;

    // Simple bob for idle/run.
    double bob = 0;
    if (state == PlayerState.idle) bob = sin(t * 3) * 1.5;
    if (state == PlayerState.run) bob = sin(t * 14).abs() * -2;

    if (state == PlayerState.dead) {
      // Lying down.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h - 12, w, 10),
          const Radius.circular(3),
        ),
        bodyPaint,
      );
      canvas.restore();
      return;
    }

    // Legs.
    final legSwing =
        state == PlayerState.run ? sin(t * 14) * 5 : 0.0;
    canvas.drawRect(
        Rect.fromLTWH(w * 0.28 + legSwing, h * 0.62, 6, h * 0.38), bodyPaint);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.55 - legSwing, h * 0.62, 6, h * 0.38), bodyPaint);

    // Torso.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.28 + bob, w * 0.6, h * 0.4),
        const Radius.circular(4),
      ),
      armorPaint,
    );

    // Head.
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.18 + bob), w * 0.18, bodyPaint);
    // Eye slit.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.52, h * 0.15 + bob, w * 0.14, 2.5),
      Paint()..color = const Color(0xFFE7433B),
    );

    // Blade.
    final bladePaint = Paint()..color = _bladeColor;
    final glowPaint = Paint()
      ..color = _bladeGlow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    if (state.isAttacking) {
      // Swing arc: angle proceeds with attackProgress.
      final startAngle = -pi / 2.2;
      final endAngle = pi / 2.6;
      final angle = startAngle + (endAngle - startAngle) * attackProgress;
      canvas.save();
      canvas.translate(w * 0.62, h * 0.42 + bob);
      canvas.rotate(angle);
      canvas.drawRect(Rect.fromLTWH(0, -2.5, w * 1.05, 5), glowPaint);
      canvas.drawRect(Rect.fromLTWH(0, -1.5, w * 1.0, 3), bladePaint);
      canvas.restore();
    } else if (state == PlayerState.block) {
      // Blade held vertically in front.
      canvas.drawRect(
          Rect.fromLTWH(w * 0.78, h * 0.1, 4, h * 0.55), glowPaint);
      canvas.drawRect(
          Rect.fromLTWH(w * 0.79, h * 0.1, 2.5, h * 0.55), bladePaint);
    } else {
      // Blade on the back.
      canvas.save();
      canvas.translate(w * 0.25, h * 0.5 + bob);
      canvas.rotate(-pi / 3.4);
      canvas.drawRect(Rect.fromLTWH(0, -2, w * 0.95, 4), glowPaint);
      canvas.drawRect(Rect.fromLTWH(0, -1.2, w * 0.9, 2.6), bladePaint);
      canvas.restore();
    }

    // Dash trail.
    if (state == PlayerState.dash) {
      final trail = Paint()..color = const Color(0x407B2FF2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.5, h * 0.25, w * 0.5, h * 0.5),
          const Radius.circular(6),
        ),
        trail,
      );
    }

    canvas.restore();
  }
}
