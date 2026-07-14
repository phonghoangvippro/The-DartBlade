import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../core/services/audio_service.dart';
import '../game/darkblade_game.dart';

/// Settings overlay (FR-036): audio toggles + volume sliders.
class SettingsMenu extends StatefulWidget {
  const SettingsMenu({super.key, required this.game});

  final DarkbladeGame game;

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  final audio = AudioService.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16121E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF7B2FF2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Color(0xFFB388FF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _toggle('Music', audio.musicEnabled, (v) {
                setState(() => audio.musicEnabled = v);
                if (!v) audio.stopMusic();
              }),
              _slider('Music Volume', audio.musicVolume,
                  (v) => setState(() => audio.musicVolume = v)),
              const SizedBox(height: 8),
              _toggle('Sound Effects', audio.sfxEnabled,
                  (v) => setState(() => audio.sfxEnabled = v)),
              _slider('SFX Volume', audio.sfxVolume,
                  (v) => setState(() => audio.sfxVolume = v)),
              const Divider(color: Colors.white12),
              _toggle(
                'Touch Controls (on-screen buttons)',
                widget.game.touchControlsEnabled,
                (v) =>
                    setState(() => widget.game.touchControlsEnabled = v),
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE0C9FF),
                    side: const BorderSide(color: Color(0xFF7B2FF2)),
                  ),
                  onPressed: () =>
                      widget.game.overlays.remove(OverlayIds.settingsMenu),
                  child: const Text('BACK',
                      style: TextStyle(letterSpacing: 3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      value: value,
      activeThumbColor: const Color(0xFFB388FF),
      onChanged: onChanged,
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            activeColor: const Color(0xFF7B2FF2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
