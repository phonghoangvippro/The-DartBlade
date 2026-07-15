import 'dart:math';

import 'package:flutter/material.dart';

import '../boss/boss.dart';
import '../game/darkblade_game.dart';
import '../player/player.dart';

class Hud extends StatefulWidget {
  const Hud({super.key, required this.game});

  final DarkbladeGame game;

  @override
  State<Hud> createState() => _HudState();
}

class _HudState extends State<Hud> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  int _lastRebuildMs = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addListener(_tick)
          ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    if (widget.game.phase != GamePhase.playing || !widget.game.playerReady) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastRebuildMs < 33) return;
    _lastRebuildMs = now;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (game.phase != GamePhase.playing || !game.playerReady) {
      return const SizedBox.shrink();
    }

    final player = game.player;
    final rightPad = game.touchControlsEnabled ? 80.0 : 12.0;
    final pulse = sin(_pulseCtrl.value * 2 * pi) * 0.5 + 0.5;

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, rightPad, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statBars(player, pulse),
                const Spacer(),
                _soulsCounter(player.stats.souls, pulse),
              ],
            ),
            const SizedBox(height: 6),
            _cooldownRow(player, pulse),
            const Spacer(),
            _bossBar(game.activeBoss.value, pulse),
            _toast(game.toast.value),
            const SizedBox(height: 4),
            if (!game.touchControlsEnabled) _controlsHint(),
          ],
        ),
      ),
    );
  }

  Widget _statBars(Player player, double pulse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(
          player.health.ratio,
          const Color(0xFFD64545),
          180,
          14,
          'HP',
          pulse,
          true,
        ),
        const SizedBox(height: 4),
        _bar(
          player.stats.manaRatio,
          const Color(0xFF4573D6),
          130,
          10,
          'MP',
          pulse,
          false,
        ),
        const SizedBox(height: 4),
        _bar(
          player.stats.staminaRatio,
          const Color(0xFF45D67E),
          150,
          10,
          'ST',
          pulse,
          false,
        ),
      ],
    );
  }

  Widget _bar(
    double ratio,
    Color color,
    double width,
    double height,
    String label,
    double pulse,
    bool isHp,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isHp
                  ? Color.lerp(
                      const Color(0xFFD64545).withValues(alpha: 0.6),
                      const Color(0xFFAA2222),
                      pulse,
                    )!
                  : Colors.white24,
            ),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isHp && ratio < 0.3
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFF0000,
                          ).withValues(alpha: 0.3 + pulse * 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _soulsCounter(int souls, double pulse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC0D0D14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7B2FF2).withValues(alpha: 0.5 + pulse * 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.blur_on,
            color: const Color(0xFFB388FF).withValues(alpha: 0.7 + pulse * 0.3),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$souls',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cooldownRow(Player player, double pulse) {
    return Row(
      children: [
        _cooldownIcon(
          player.unlockDash ? 'DASH' : '???',
          1 - player.dashCooldownRatio,
          Icons.double_arrow,
          player.unlockDash,
          pulse,
        ),
        const SizedBox(width: 8),
        _cooldownIcon(
          'SKILL',
          1 - player.skillCooldownRatio,
          Icons.flash_on,
          true,
          pulse,
        ),
      ],
    );
  }

  Widget _cooldownIcon(
    String label,
    double readiness,
    IconData icon,
    bool unlocked,
    double pulse,
  ) {
    final ready = readiness >= 0.999 && unlocked;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ready
                      ? const Color(
                          0xFF7B2FF2,
                        ).withValues(alpha: 0.7 + pulse * 0.3)
                      : Colors.white24,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: ready
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            if (!ready && unlocked)
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
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: unlocked ? 0.7 : 0.3),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _bossBar(Boss? boss, double pulse) {
    if (boss == null || boss.isDead) return const SizedBox.shrink();
    return Center(
      child: Column(
        children: [
          Text(
            boss.archetype.name,
            style: TextStyle(
              color: const Color(
                0xFFE0C9FF,
              ).withValues(alpha: 0.8 + pulse * 0.2),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              shadows: [
                Shadow(
                  color: boss.archetype.auraColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 420,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(
                color: const Color(0xFF7B2FF2).withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: boss.health.ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          boss.archetype.auraColor,
                          const Color(0xFF9C2B2B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xCC0D0D14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF7B2FF2).withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFE0C9FF),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _controlsHint() {
    return Text(
      'A/D move  ·  SPACE jump  ·  J attack  ·  K dash  ·  L block  ·  '
      'I skill  ·  Q potion  ·  E inventory  ·  ESC pause',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.2),
        fontSize: 10,
      ),
    );
  }
}
