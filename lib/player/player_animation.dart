import 'dart:math';
import 'dart:ui';

import 'player_state.dart';

class PlayerAnimator {
  // Ash colors
  static const Color _hairColor = Color(0xFF0A0A0A);
  static const Color _skinColor = Color(0xFFD4C4B0);
  static const Color _armorDark = Color(0xFF1E1E2E);
  static const Color _armorLight = Color(0xFF3A3A4E);
  static const Color _leatherColor = Color(0xFF3A2A1A);
  static const Color _cloakColor = Color(0xFF2A2A3A);
  static const Color _bladeColor = Color(0xFF0A0018);
  static const Color _bladeGlow = Color(0xFF7B2FF2);
  static const Color _bladeLava = Color(0xFFFF4400);
  static const Color _hurtColor = Color(0xFFB03A48);

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
    if (facing < 0) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    if (invincible && (t * 20).floor().isEven) {
      canvas.restore();
      return;
    }

    final w = size.width;
    final h = size.height;
    final isHurt = state == PlayerState.hurt;
    final bodyPaint = Paint()..color = isHurt ? _hurtColor : _armorDark;
    final armorPaint = Paint()..color = _armorLight;

    double bob = 0;
    if (state == PlayerState.idle) bob = sin(t * 3) * 1.5;
    if (state == PlayerState.run) bob = sin(t * 14).abs() * -2;

    if (state == PlayerState.dead) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h - 12, w, 10),
          const Radius.circular(3),
        ),
        Paint()..color = _armorDark,
      );
      canvas.restore();
      return;
    }

    // A translucent aura is substantially cheaper than a runtime blur.
    final auraAlpha = 0.04 + sin(t * 2.5) * 0.02;
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.4 + bob),
      w * 0.6,
      Paint()..color = _bladeGlow.withValues(alpha: auraAlpha),
    );

    // Cloak
    final cloakPaint = Paint()..color = _cloakColor;
    final cloakSway = state == PlayerState.run
        ? sin(t * 12) * 4
        : sin(t * 2) * 2;
    final cloakPath = Path()
      ..moveTo(w * 0.1, h * 0.25 + bob)
      ..lineTo(w * 0.2 + cloakSway, h * 0.9 + bob)
      ..lineTo(w * 0.45, h * 0.85 + bob)
      ..lineTo(w * 0.5, h * 0.3 + bob)
      ..close();
    canvas.drawPath(cloakPath, cloakPaint);

    // Legs
    final legSwing = state == PlayerState.run ? sin(t * 14) * 5 : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.28 + legSwing, h * 0.62, 6, h * 0.38),
      Paint()..color = _leatherColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.55 - legSwing, h * 0.62, 6, h * 0.38),
      Paint()..color = _leatherColor,
    );

    // Boots
    canvas.drawRect(
      Rect.fromLTWH(w * 0.26 + legSwing, h * 0.88, 10, h * 0.12),
      Paint()..color = const Color(0xFF1A1A1A),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.53 - legSwing, h * 0.88, 10, h * 0.12),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Torso (leather armor + metal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.28 + bob, w * 0.6, h * 0.4),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Metal shoulder pads
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.26 + bob, w * 0.16, h * 0.12),
        const Radius.circular(3),
      ),
      armorPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.74, h * 0.26 + bob, w * 0.16, h * 0.12),
        const Radius.circular(3),
      ),
      armorPaint,
    );

    // Belt
    canvas.drawRect(
      Rect.fromLTWH(w * 0.2, h * 0.56 + bob, w * 0.6, h * 0.04),
      Paint()..color = const Color(0xFF1A1A0A),
    );
    // Belt buckle
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.55 + bob, w * 0.1, h * 0.06),
      Paint()..color = const Color(0xFF8A7A4A),
    );

    // Arms
    canvas.drawRect(
      Rect.fromLTWH(w * 0.05, h * 0.32 + bob, w * 0.12, h * 0.26),
      Paint()..color = _leatherColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.83, h * 0.32 + bob, w * 0.12, h * 0.26),
      Paint()..color = _leatherColor,
    );

    // Head
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.18 + bob),
      w * 0.18,
      Paint()..color = _skinColor,
    );

    // Hair
    final hairPaint = Paint()..color = _hairColor;
    canvas.drawCircle(Offset(w * 0.5, h * 0.14 + bob), w * 0.19, hairPaint);
    // Hair fringe
    canvas.drawRect(
      Rect.fromLTWH(w * 0.32, h * 0.12 + bob, w * 0.18, h * 0.08),
      hairPaint,
    );

    // Face scar
    canvas.drawLine(
      Offset(w * 0.48, h * 0.17 + bob),
      Offset(w * 0.58, h * 0.2 + bob),
      Paint()
        ..color = const Color(0xFF8A6A5A)
        ..strokeWidth = 1.5,
    );

    // Eyes
    final eyeIsDark =
        state == PlayerState.attack1 ||
        state == PlayerState.attack2 ||
        state == PlayerState.attack3 ||
        state == PlayerState.hurt;
    final eyeColor = eyeIsDark
        ? const Color(0xFFFF2244)
        : const Color(0xFFC0B8B0);
    canvas.drawCircle(
      Offset(w * 0.44, h * 0.17 + bob),
      2,
      Paint()..color = eyeColor,
    );
    canvas.drawCircle(
      Offset(w * 0.56, h * 0.17 + bob),
      2,
      Paint()..color = eyeColor,
    );

    // DarkBlade glow on eyes when attacking
    if (eyeIsDark) {
      final glow = Paint()
        ..color = _bladeGlow.withValues(alpha: 0.3 + sin(t * 5) * 0.2);
      canvas.drawCircle(Offset(w * 0.44, h * 0.17 + bob), 4, glow);
      canvas.drawCircle(Offset(w * 0.56, h * 0.17 + bob), 4, glow);
    }

    // Mouth
    canvas.drawLine(
      Offset(w * 0.44, h * 0.22 + bob),
      Offset(w * 0.56, h * 0.22 + bob),
      Paint()
        ..color = const Color(0xFF8A6A5A)
        ..strokeWidth = 1.5,
    );

    // =================================================================
    // THE DARKBLADE - Legendary Sword
    // =================================================================
    final bladePaint = Paint()..color = _bladeColor;
    final glowPaint = Paint()
      ..color = _bladeGlow.withValues(alpha: 0.4 + sin(t * 3) * 0.15);
    final lavaPaint = Paint()..color = _bladeLava;

    if (state.isAttacking) {
      // Swing arc
      final startAngle = -pi / 2.2;
      final endAngle = pi / 2.6;
      final angle = startAngle + (endAngle - startAngle) * attackProgress;
      final swingAlpha = 0.6 - (attackProgress - 0.5).abs() * 0.8;

      canvas.save();
      canvas.translate(w * 0.65, h * 0.42 + bob);
      canvas.rotate(angle);

      // Trail effect
      canvas.drawRect(
        Rect.fromLTWH(-5, -4, w * 1.3, 8),
        Paint()..color = _bladeGlow.withValues(alpha: swingAlpha * 0.18),
      );

      // Blade glow
      canvas.drawRect(Rect.fromLTWH(0, -3, w * 1.2, 6), glowPaint);
      // Blade core
      canvas.drawRect(Rect.fromLTWH(0, -2, w * 1.15, 4), bladePaint);
      // Lava cracks
      canvas.drawLine(
        Offset(w * 0.2, 0),
        Offset(w * 0.8, 0),
        lavaPaint..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(w * 0.1, -1),
        Offset(w * 0.4, 1),
        lavaPaint..strokeWidth = 1,
      );

      // Guard
      canvas.drawRect(
        Rect.fromLTWH(-3, -5, 6, 10),
        Paint()..color = const Color(0xFF4A3A2A),
      );

      canvas.restore();

      // Swing trail particles
      if (attackProgress > 0.1 && attackProgress < 0.9) {
        final trailPaint = Paint()
          ..color = _bladeGlow.withValues(alpha: swingAlpha * 0.12);
        canvas.drawCircle(
          Offset(w * 0.8, h * 0.25 + bob + attackProgress * h * 0.3),
          w * 0.1,
          trailPaint,
        );
      }
    } else if (state == PlayerState.block) {
      // Blade held vertically in front
      canvas.save();
      canvas.translate(w * 0.78, h * 0.05 + bob);
      canvas.drawRect(Rect.fromLTWH(0, 0, 5, h * 0.6), glowPaint);
      canvas.drawRect(Rect.fromLTWH(1, 0, 3, h * 0.6), bladePaint);
      // Lava vein
      canvas.drawLine(
        Offset(2, h * 0.1),
        Offset(2, h * 0.5),
        lavaPaint..strokeWidth = 1.5,
      );
      // Guard
      canvas.drawRect(
        Rect.fromLTWH(-3, -2, 6, 6),
        Paint()..color = const Color(0xFF4A3A2A),
      );
      canvas.restore();
    } else if (state == PlayerState.dash) {
      // Blade extended forward
      canvas.save();
      canvas.translate(w * 0.6, h * 0.4 + bob);
      canvas.rotate(-pi / 6);
      canvas.drawRect(Rect.fromLTWH(0, -2.5, w * 1.1, 5), glowPaint);
      canvas.drawRect(Rect.fromLTWH(0, -1.5, w * 1.05, 3), bladePaint);
      canvas.drawLine(
        Offset(w * 0.15, 0),
        Offset(w * 0.75, 0),
        lavaPaint..strokeWidth = 1.5,
      );
      canvas.restore();

      // Dash trail
      final trail = Paint()..color = _bladeGlow.withValues(alpha: 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.3, h * 0.2, w * 0.4, h * 0.6),
          const Radius.circular(8),
        ),
        trail,
      );
    } else {
      // Blade on the back (sheathed position)
      canvas.save();
      canvas.translate(w * 0.22, h * 0.45 + bob);
      canvas.rotate(-pi / 3.4);

      // Back glow
      canvas.drawRect(
        Rect.fromLTWH(-2, -3, w * 1.0, 6),
        Paint()..color = _bladeGlow.withValues(alpha: 0.10),
      );
      // Blade
      canvas.drawRect(Rect.fromLTWH(0, -2, w * 0.95, 4), glowPaint);
      canvas.drawRect(Rect.fromLTWH(0, -1.2, w * 0.9, 2.6), bladePaint);
      // Lava crack
      canvas.drawLine(
        Offset(w * 0.1, 0),
        Offset(w * 0.6, 0),
        lavaPaint..strokeWidth = 1,
      );
      // Guard
      canvas.drawRect(
        Rect.fromLTWH(-3, -4, 6, 8),
        Paint()..color = const Color(0xFF4A3A2A),
      );

      canvas.restore();
    }

    canvas.restore();
  }
}
