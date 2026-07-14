import 'package:flutter/material.dart';

import '../boss/boss.dart';
import '../game/darkblade_game.dart';
import '../player/player.dart';

/// In-game HUD (plan section 15): HP / Mana / Stamina bars, souls counter,
/// skill & dash cooldowns, boss health bar and toast messages.
class Hud extends StatefulWidget {
  const Hud({super.key, required this.game});

  final DarkbladeGame game;

  @override
  State<Hud> createState() => _HudState();
}

class _HudState extends State<Hud> {
  @override
  void initState() {
    super.initState();
    // Repaint HUD every frame while mounted.
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    // Only render while actively playing (menus draw their own screens).
    if (game.phase != GamePhase.playing || !game.playerReady) {
      return const SizedBox.shrink();
    }

    final player = game.player;

    final rightPad = game.touchControlsEnabled ? 80.0 : 12.0;
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, rightPad, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statBars(player),
                const Spacer(),
                _soulsCounter(player.stats.souls),
              ],
            ),
            const SizedBox(height: 6),
            _cooldownRow(player),
            const Spacer(),
            _bossBar(game.activeBoss.value),
            _toast(game.toast.value),
            const SizedBox(height: 4),
            // Keyboard hint is pointless when playing with touch buttons.
            if (!game.touchControlsEnabled) _controlsHint(),
          ],
        ),
      ),
    );
  }

  Widget _statBars(Player player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(player.health.ratio, const Color(0xFFD64545), 180, 14, 'HP'),
        const SizedBox(height: 4),
        _bar(player.stats.manaRatio, const Color(0xFF4573D6), 130, 10, 'MP'),
        const SizedBox(height: 4),
        _bar(player.stats.staminaRatio, const Color(0xFF45D67E), 150, 10,
            'ST'),
      ],
    );
  }

  Widget _bar(
      double ratio, Color color, double width, double height, String label) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white24),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _soulsCounter(int souls) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B2FF2), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.blur_on, color: Color(0xFFB388FF), size: 16),
          const SizedBox(width: 6),
          Text('$souls',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _cooldownRow(Player player) {
    return Row(
      children: [
        _cooldownIcon('DASH', 1 - player.dashCooldownRatio, Icons.double_arrow),
        const SizedBox(width: 8),
        _cooldownIcon(
            'SKILL', 1 - player.skillCooldownRatio, Icons.flash_on),
      ],
    );
  }

  Widget _cooldownIcon(String label, double readiness, IconData icon) {
    final ready = readiness >= 0.999;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: ready ? const Color(0xFF7B2FF2) : Colors.white24),
              ),
              child: Icon(icon,
                  size: 18,
                  color: ready ? Colors.white : Colors.white38),
            ),
            if (!ready)
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  value: readiness,
                  strokeWidth: 2,
                  color: const Color(0xFFB388FF),
                ),
              ),
          ],
        ),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 8)),
      ],
    );
  }

  Widget _bossBar(Boss? boss) {
    if (boss == null || boss.isDead) return const SizedBox.shrink();
    return Center(
      child: Column(
        children: [
          Text(
            boss.archetype.name,
            style: const TextStyle(
              color: Color(0xFFE0C9FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 420,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(color: const Color(0xFF7B2FF2)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: boss.health.ratio,
              child: Container(color: const Color(0xFF9C2B2B)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _toast(String? message) {
    if (message == null) return const SizedBox(height: 24);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFE0C9FF), fontSize: 13),
        ),
      ),
    );
  }

  Widget _controlsHint() {
    return const Text(
      'A/D move  ·  SPACE jump  ·  J attack  ·  K dash  ·  L block  ·  '
      'I skill  ·  Q potion  ·  E inventory  ·  ESC pause',
      style: TextStyle(color: Colors.white24, fontSize: 10),
    );
  }
}
