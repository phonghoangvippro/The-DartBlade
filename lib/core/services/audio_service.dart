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

  Future<void> playSfx(String fileName) async {
    if (!sfxEnabled) return;
    try {
      await FlameAudio.play(fileName, volume: sfxVolume);
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
