import 'dart:async';

import 'package:flutter/material.dart';

import '../game/darkblade_game.dart';

class TouchControls extends StatefulWidget {
  const TouchControls({super.key, required this.game});

  final DarkbladeGame game;

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  static const _refreshInterval = Duration(milliseconds: 200);

  DarkbladeGame get game => widget.game;
  Timer? _refreshTimer;
  bool _wasActive = false;

  bool get _active =>
      game.touchControlsEnabled &&
      game.playerReady &&
      game.phase == GamePhase.playing;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _tick());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _releaseAll();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final active = _active;
    if (_wasActive && !active) _releaseAll();
    if (!active && active == _wasActive) return;
    _wasActive = active;
    setState(() {});
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
      return const SizedBox.shrink();
    }
    final c = game.player.controller;

    return SafeArea(
      child: Stack(
        children: [
          // --------------------------------------------------- left: move
          Positioned(
            left: 50,
            bottom: 24,
            child: Row(
              children: [
                _holdButton(
                  size: 85,
                  child: const Icon(
                    Icons.arrow_left,
                    color: Colors.white60,
                    size: 60,
                  ),
                  onDown: () => c.touchMoveDirection = -1,
                  onUp: () {
                    if (c.touchMoveDirection < 0) c.touchMoveDirection = 0;
                  },
                ),
                const SizedBox(width: 12),
                _holdButton(
                  size: 85,
                  child: const Icon(
                    Icons.arrow_right,
                    color: Colors.white60,
                    size: 60,
                  ),
                  onDown: () => c.touchMoveDirection = 1,
                  onUp: () {
                    if (c.touchMoveDirection > 0) c.touchMoveDirection = 0;
                  },
                ),
              ],
            ),
          ),
          if (game.canInteract.value)
            Positioned(
              right: 22,
              bottom: 300,
              child: _holdButton(
                size: 58,
                label: 'TALK',
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFFB388FF),
                  size: 22,
                ),
                onDown: game.interactWithNpc,
                onUp: () {},
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
                    right: 45,
                    bottom: 110,
                    child: _holdButton(
                      size: 70,
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
                    right: 115,
                    bottom: 75,
                    child: _holdButton(
                      size: 70,
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
                      size: 85,
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
                    right: 150,
                    bottom: 4,
                    child: _holdButton(
                      size: 70,
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
                    right: 240,
                    bottom: 4,
                    child: _holdButton(
                      size: 45,
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
                    right: 295,
                    bottom: 4,
                    child: _tapButton(
                      size: 45,
                      label: 'POTION ×${game.potionCount}',
                      ready: game.canUsePotion,
                      onTap: game.useEquippedPotion,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.local_drink,
                            color: Color(0xFFE05252),
                            size: 22,
                          ),
                          Positioned(
                            right: 8,
                            bottom: 6,
                            child: Text(
                              '${game.potionCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _tapButton({
    required double size,
    required Widget child,
    required VoidCallback onTap,
    required String label,
    bool ready = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: ready ? onTap : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: ready ? const Color(0x99E05252) : Colors.white10,
                width: 2,
              ),
            ),
            child: Opacity(opacity: ready ? 0.75 : 0.30, child: child),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: TextStyle(
              color: ready ? Colors.white54 : Colors.white24,
              fontSize: 8,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}
