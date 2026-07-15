import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';
import '../story/dialogue.dart';
import 'level_data.dart';

class Npc extends PositionComponent with HasGameReference<DarkbladeGame> {
  Npc({required Vector2 position, required this.definition})
    : super(
        position: position,
        size: Vector2(34, 52),
        anchor: Anchor.bottomCenter,
      ) {
    priority = GameConstants.priorityPlayer - 1;
  }

  final NpcDef definition;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (game.phase != GamePhase.playing) return;
    final distance = absoluteCenter.distanceTo(game.player.absoluteCenter);
    if (distance <= 90) {
      game.offerInteraction(this, distance);
    } else {
      game.clearInteraction(this);
    }
  }

  void interact() {
    game.showDialogue([
      DialogueLine(
        speaker: definition.name,
        text: definition.dialogue,
        color: definition.accent,
      ),
    ]);
  }

  @override
  void onRemove() {
    game.clearInteraction(this);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (game.playerReady &&
        absoluteCenter.distanceTo(game.player.absoluteCenter) > 760) {
      return;
    }
    final bob = sin(_time * 2) * 1.2;
    final glow = Paint()..color = definition.accent.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.x / 2, size.y * 0.45 + bob), 27, glow);
    glow.color = definition.accent.withValues(alpha: 0.14);
    canvas.drawCircle(Offset(size.x / 2, size.y * 0.45 + bob), 18, glow);

    switch (definition.kind) {
      case NpcKind.blindPriest:
        canvas.drawPath(
          Path()
            ..moveTo(6, 50)
            ..lineTo(17, 16 + bob)
            ..lineTo(29, 50)
            ..close(),
          Paint()..color = const Color(0xFF292335),
        );
        canvas.drawCircle(
          Offset(17, 12 + bob),
          8,
          Paint()..color = const Color(0xFFC8B8A8),
        );
        canvas.drawRect(
          Rect.fromLTWH(10, 10 + bob, 14, 4),
          Paint()..color = const Color(0xFFE8E0D8),
        );
        canvas.drawLine(
          const Offset(28, 18),
          const Offset(31, 52),
          Paint()
            ..color = const Color(0xFF8A6844)
            ..strokeWidth = 3,
        );
      case NpcKind.merchant:
        canvas.drawPath(
          Path()
            ..moveTo(3, 50)
            ..lineTo(17, 13 + bob)
            ..lineTo(32, 50)
            ..close(),
          Paint()..color = const Color(0xFF181522),
        );
        canvas.drawCircle(
          Offset(17, 13 + bob),
          9,
          Paint()..color = const Color(0xFFE0D4B8),
        );
        canvas.drawCircle(
          Offset(14, 12 + bob),
          1.5,
          Paint()..color = const Color(0xFF111111),
        );
        canvas.drawCircle(
          Offset(20, 12 + bob),
          1.5,
          Paint()..color = const Color(0xFF111111),
        );
        canvas.drawArc(
          Rect.fromLTWH(12, 11 + bob, 10, 8),
          0,
          pi,
          false,
          Paint()
            ..color = const Color(0xFF5A2030)
            ..strokeWidth = 1.5,
        );
      case NpcKind.littleGhost:
        canvas.drawPath(
          Path()
            ..moveTo(7, 48)
            ..quadraticBezierTo(17, 5 + bob, 27, 48)
            ..quadraticBezierTo(22, 43, 17, 49)
            ..quadraticBezierTo(12, 43, 7, 48),
          Paint()..color = const Color(0x9955CCFF),
        );
        canvas.drawCircle(
          Offset(17, 13 + bob),
          8,
          Paint()..color = const Color(0xAACCEEFF),
        );
        canvas.drawCircle(
          Offset(14, 13 + bob),
          1.5,
          Paint()..color = const Color(0xFF3377AA),
        );
        canvas.drawCircle(
          Offset(20, 13 + bob),
          1.5,
          Paint()..color = const Color(0xFF3377AA),
        );
    }
  }
}
