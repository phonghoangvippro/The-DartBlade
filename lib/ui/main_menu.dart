import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

/// Main menu overlay (FR-033): Play / Continue / Exit.
class MainMenu extends StatelessWidget {
  const MainMenu({super.key, required this.game});

  final DarkbladeGame game;

  @override
  Widget build(BuildContext context) {
    final hasSave = game.saveService.hasSave;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D14), Color(0xFF1D1030)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'THE DARKBLADE',
              style: TextStyle(
                color: Color(0xFFB388FF),
                fontSize: 46,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
                shadows: [
                  Shadow(color: Color(0xFF7B2FF2), blurRadius: 24),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'A 2D Souls-like Action RPG',
              style: TextStyle(
                  color: Colors.white38, fontSize: 14, letterSpacing: 3),
            ),
            const SizedBox(height: 48),
            _MenuButton(
              label: 'NEW GAME',
              onPressed: game.startNewGame,
            ),
            if (hasSave) ...[
              const SizedBox(height: 12),
              _MenuButton(
                label: 'CONTINUE',
                onPressed: game.continueGame,
              ),
            ],
            const SizedBox(height: 12),
            _MenuButton(
              label: 'SETTINGS',
              onPressed: () =>
                  game.overlays.add(OverlayIds.settingsMenu),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE0C9FF),
          side: const BorderSide(color: Color(0xFF7B2FF2)),
          backgroundColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(letterSpacing: 4, fontSize: 15),
        ),
      ),
    );
  }
}
