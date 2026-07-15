import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

/// Victory screen shown after the final boss falls.
class VictoryMenu extends StatelessWidget {
  const VictoryMenu({super.key, required this.game});

  final DarkbladeGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF2A1745), Color(0xFF0D0D14)],
          radius: 1.2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'THE CURSE IS BROKEN',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                shadows: [Shadow(color: Color(0xFF7B2FF2), blurRadius: 30)],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The Darkblade rests at last.\n'
              'Its secret dies with the Dark King.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Souls collected: ${game.player.stats.souls}',
              style: const TextStyle(color: Color(0xFFB388FF), fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 240,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE0C9FF),
                  side: const BorderSide(color: Color(0xFF7B2FF2)),
                ),
                onPressed: () {
                  game.overlays.remove(OverlayIds.victory);
                  game.phase = GamePhase.menu;
                  game.overlays.add(OverlayIds.mainMenu);
                },
                child: const Text(
                  'MAIN MENU',
                  style: TextStyle(letterSpacing: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
