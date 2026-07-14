import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

/// "YOU DIED" screen (FR-037) - souls-like style.
class GameOverMenu extends StatelessWidget {
  const GameOverMenu({super.key, required this.game});

  final DarkbladeGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'YOU DIED',
              style: TextStyle(
                color: Color(0xFF9C2B2B),
                fontSize: 52,
                fontWeight: FontWeight.bold,
                letterSpacing: 14,
                shadows: [Shadow(color: Colors.red, blurRadius: 30)],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Half of your souls were lost...',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 260,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE0C9FF),
                  side: const BorderSide(color: Color(0xFF7B2FF2)),
                ),
                onPressed: game.respawnPlayer,
                child: const Text('RETURN TO CHECKPOINT',
                    style: TextStyle(letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 260,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                ),
                onPressed: () {
                  game.overlays.remove(OverlayIds.gameOver);
                  game.phase = GamePhase.menu;
                  game.overlays.add(OverlayIds.mainMenu);
                },
                child: const Text('QUIT TO MENU',
                    style: TextStyle(letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
