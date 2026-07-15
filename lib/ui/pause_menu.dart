import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

/// Pause overlay (FR-034).
class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key, required this.game});

  final DarkbladeGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Color(0xFFB388FF),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 32),
            _button('RESUME', game.togglePause),
            const SizedBox(height: 10),
            _button(
              'SETTINGS',
              () => game.overlays.add(OverlayIds.settingsMenu),
            ),
            const SizedBox(height: 10),
            _button('SAVE GAME', () async {
              await game.saveProgress();
              game.showToast('Game saved');
            }),
            const SizedBox(height: 10),
            _button('QUIT TO MENU', () async {
              await game.saveProgress();
              game.overlays.remove(OverlayIds.pauseMenu);
              game.phase = GamePhase.menu;
              game.overlays.add(OverlayIds.mainMenu);
            }),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 220,
      height: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE0C9FF),
          side: const BorderSide(color: Color(0xFF7B2FF2)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(letterSpacing: 3)),
      ),
    );
  }
}
