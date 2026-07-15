import 'package:flame_audio/flame_audio.dart';

import '../logger/game_logger.dart';

/// Wrapper around [FlameAudio].
///
/// All calls fail gracefully when audio files are missing, so the game keeps
/// running even before audio assets are added to `assets/audio/`.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 0.6;
  double sfxVolume = 0.8;
  final Map<String, AudioPool> _sfxPools = {};

  static const _pooledSfx = {
    'block.wav': 3,
    'boss_attack.wav': 3,
    'boss_skill.wav': 3,
    'dash.wav': 2,
    'enemy_attack.wav': 4,
    'hurt.wav': 3,
    'jump.wav': 2,
    'skill.wav': 3,
    'sword_swing.wav': 3,
  };

  static const _assets = [
    'abyss_theme.wav',
    'block.wav',
    'boss_attack.wav',
    'boss_death.wav',
    'boss_rage.wav',
    'boss_roar.wav',
    'boss_skill.wav',
    'boss_theme.wav',
    'boss_ultimate.wav',
    'castle_theme.wav',
    'checkpoint.wav',
    'dash.wav',
    'death.wav',
    'enemy_attack.wav',
    'enemy_death.wav',
    'forest_theme.wav',
    'hurt.wav',
    'jump.wav',
    'pickup.wav',
    'potion.wav',
    'skill.wav',
    'sword_swing.wav',
    'theme.wav',
    'village_theme.wav',
  ];

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_assets);
      for (final entry in _pooledSfx.entries) {
        _sfxPools[entry.key] = await FlameAudio.createPool(
          entry.key,
          minPlayers: 1,
          maxPlayers: entry.value,
        );
      }
    } catch (e) {
      GameLogger.warn('Audio', 'Could not preload all audio: $e');
    }
  }

  Future<void> playSfx(String fileName) async {
    if (!sfxEnabled) return;
    try {
      final pool = _sfxPools[fileName];
      if (pool != null) {
        await pool.start(volume: sfxVolume);
      } else {
        await FlameAudio.play(fileName, volume: sfxVolume);
      }
    } catch (e) {
      GameLogger.warn('Audio', 'Missing sfx "$fileName" (skipped)');
    }
  }

  Future<void> playMusic(String fileName) async {
    if (!musicEnabled) return;
    try {
      await FlameAudio.bgm.play(fileName, volume: musicVolume);
    } catch (e) {
      GameLogger.warn('Audio', 'Missing music "$fileName" (skipped)');
    }
  }

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }
}
