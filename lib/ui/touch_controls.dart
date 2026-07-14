import 'package:flutter/material.dart';

import '../game/darkblade_game.dart';

class TouchControls extends StatefulWidget {
  const TouchControls({super.key, required this.game});

  final DarkbladeGame game;

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  DarkbladeGame get game => widget.game;

  bool get _active =>
      game.touchControlsEnabled &&
      game.playerReady &&
      game.phase == GamePhase.playing;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  void _releaseAll() {
    if (!game.playerReady) return;
    final c = game.player.controller;
    c
      ..touchMoveDirection = 0
      ..touchJumpHeld = false
      ..touchAttackHeld = false
      ..touchDashHeld = false
      ..touchBlockHeld = false
      ..touchSkillHeld = false
      ..touchPotionHeld = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      _releaseAll();
      return const SizedBox.shrink();
    }
    final c = game.player.controller;

    return SafeArea(
      child: Stack(
        children: [
          // --------------------------------------------------- left: move
          Positioned(
            left: 12,
            bottom: 24,
            child: Row(
              children: [
                _holdButton(
                  size: 62,
                  child: const Icon(
                    Icons.arrow_left,
                    color: Colors.white60,
                    size: 36,
                  ),
                  onDown: () => c.touchMoveDirection = -1,
                  onUp: () {
                    if (c.touchMoveDirection < 0) c.touchMoveDirection = 0;
                  },
                ),
                const SizedBox(width: 12),
                _holdButton(
                  size: 62,
                  child: const Icon(
                    Icons.arrow_right,
                    color: Colors.white60,
                    size: 36,
                  ),
                  onDown: () => c.touchMoveDirection = 1,
                  onUp: () {
                    if (c.touchMoveDirection > 0) c.touchMoveDirection = 0;
                  },
                ),
              ],
            ),
          ),

          // ---------------------------------------------------- top-right: menu
          Positioned(
            top: 4,
            right: 10,
            child: Row(
              children: [
                _menuButton(Icons.inventory_2_outlined, game.openInventory),
                const SizedBox(width: 6),
                _menuButton(Icons.pause, game.togglePause),
              ],
            ),
          ),

          // ------------------------------------------------ right: action arc
          Positioned(
            right: 0,
            bottom: 8,
            child: SizedBox(
              width: 340,
              height: 280,
              child: Stack(
                children: [
                  // BLOCK - đỉnh vòng cung
                  Positioned(
                    right: 52,
                    bottom: 102,
                    child: _holdButton(
                      size: 58,
                      label: 'BLOCK',
                      child: const Icon(
                        Icons.shield,
                        color: Color(0xFF9FB4C7),
                        size: 22,
                      ),
                      onDown: () => c.touchBlockHeld = true,
                      onUp: () => c.touchBlockHeld = false,
                    ),
                  ),
                  // SKILL - giữa vòng cung
                  Positioned(
                    right: 118,
                    bottom: 68,
                    child: _holdButton(
                      size: 58,
                      label: 'SKILL',
                      ready: game.player.skillCooldownRatio <= 0,
                      child: const Icon(
                        Icons.flash_on,
                        color: Color(0xFFB388FF),
                        size: 22,
                      ),
                      onDown: () => c.touchSkillHeld = true,
                      onUp: () => c.touchSkillHeld = false,
                    ),
                  ),
                  // JUMP 🏆 - to nhất, neo góc dưới cùng bên phải
                  Positioned(
                    right: 50,
                    bottom: 4,
                    child: _holdButton(
                      size: 76,
                      label: 'JUMP',
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 36,
                      ),
                      onDown: () => c.touchJumpHeld = true,
                      onUp: () => c.touchJumpHeld = false,
                    ),
                  ),
                  // ATTACK - cạnh trái JUMP
                  Positioned(
                    right: 145,
                    bottom: 4,
                    child: _holdButton(
                      size: 58,
                      label: 'ATTACK',
                      child: const Icon(
                        Icons.gavel,
                        color: Color(0xFFE0C9FF),
                        size: 24,
                      ),
                      onDown: () => c.touchAttackHeld = true,
                      onUp: () => c.touchAttackHeld = false,
                    ),
                  ),
                  // DASH - cạnh trái ATTACK
                  Positioned(
                    right: 210,
                    bottom: 4,
                    child: _holdButton(
                      size: 58,
                      label: 'DASH',
                      ready: game.player.dashCooldownRatio <= 0,
                      child: const Icon(
                        Icons.double_arrow,
                        color: Color(0xFF45D67E),
                        size: 24,
                      ),
                      onDown: () => c.touchDashHeld = true,
                      onUp: () => c.touchDashHeld = false,
                    ),
                  ),
                  // POTION - cạnh trái DASH
                  Positioned(
                    right: 275,
                    bottom: 4,
                    child: _holdButton(
                      size: 58,
                      label: 'POTION',
                      child: const Icon(
                        Icons.local_drink,
                        color: Color(0xFFE05252),
                        size: 22,
                      ),
                      onDown: () => c.touchPotionHeld = true,
                      onUp: () => c.touchPotionHeld = false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Icon(icon, color: Colors.white54, size: 17),
      ),
    );
  }

  Widget _holdButton({
    required double size,
    required Widget child,
    required VoidCallback onDown,
    required VoidCallback onUp,
    String? label,
    bool ready = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (_) => onDown(),
          onPointerUp: (_) => onUp(),
          onPointerCancel: (_) => onUp(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: ready ? const Color(0x667B2FF2) : Colors.white10,
                width: 2,
              ),
            ),
            child: Opacity(opacity: ready ? 0.60 : 0.30, child: child),
          ),
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}
