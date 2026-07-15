// Standalone Dart script to generate placeholder WAV audio files.
// Run with: dart tools\generate_audio.dart
// Output goes to assets/audio/

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;
const int bitsPerSample = 16;
const int numChannels = 1;
const double maxAmp = 32767;

void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  _generate(outDir, 'theme.wav', _ambientDrone(30.0));
  _generate(outDir, 'boss_theme.wav', _bossTheme(30.0));
  _generate(outDir, 'village_theme.wav', _villageTheme(30.0));
  _generate(outDir, 'forest_theme.wav', _forestTheme(30.0));
  _generate(outDir, 'castle_theme.wav', _castleTheme(30.0));
  _generate(outDir, 'abyss_theme.wav', _abyssTheme(30.0));
  _generate(outDir, 'sword_swing.wav', _swoosh(0.25));
  _generate(outDir, 'jump.wav', _jump(0.15));
  _generate(outDir, 'dash.wav', _whoosh(0.2));
  _generate(outDir, 'hurt.wav', _hurt(0.2));
  _generate(outDir, 'death.wav', _death(0.6));
  _generate(outDir, 'potion.wav', _chime(0.3));
  _generate(outDir, 'skill.wav', _powerBurst(0.4));
  _generate(outDir, 'block.wav', _clang(0.15));
  _generate(outDir, 'enemy_attack.wav', _growl(0.2));
  _generate(outDir, 'enemy_death.wav', _pop(0.2));
  _generate(outDir, 'boss_roar.wav', _roar(1.0));
  _generate(outDir, 'boss_attack.wav', _heavySwing(0.3));
  _generate(outDir, 'boss_skill.wav', _darkBuildup(0.6));
  _generate(outDir, 'boss_ultimate.wav', _explosion(0.6));
  _generate(outDir, 'boss_rage.wav', _scream(0.5));
  _generate(outDir, 'boss_death.wav', _longFade(1.5));
  _generate(outDir, 'pickup.wav', _pickup(0.25));
  _generate(outDir, 'checkpoint.wav', _checkpoint(0.8));
  
  print('Done! Generated ${_count} audio files.');
}

int _count = 0;

void _generate(Directory dir, String name, Float64List samples) {
  final wav = _encodeWav(samples);
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync(wav);
  _count++;
  print('  Created $name');
}

// ===========================================================================
// WAV ENCODER
// ===========================================================================
Uint8List _encodeWav(Float64List samples) {
  final dataSize = samples.length * 2;
  final fileSize = 44 + dataSize;

  final data = Uint8List(fileSize);
  final b = ByteData.view(data.buffer);

  int offset = 0;
  void writeString(String s) {
    for (var i = 0; i < s.length; i++) b.setUint8(offset++, s.codeUnitAt(i));
  }

  writeString('RIFF');
  b.setUint32(offset, fileSize - 8, Endian.little); offset += 4;
  writeString('WAVE');
  writeString('fmt ');
  b.setUint32(offset, 16, Endian.little); offset += 4; // chunk size
  b.setUint16(offset, 1, Endian.little); offset += 2;  // PCM
  b.setUint16(offset, numChannels, Endian.little); offset += 2;
  b.setUint32(offset, sampleRate, Endian.little); offset += 4;
  b.setUint32(offset, sampleRate * numChannels * bitsPerSample ~/ 8, Endian.little); offset += 4; // byte rate
  b.setUint16(offset, numChannels * bitsPerSample ~/ 8, Endian.little); offset += 2; // block align
  b.setUint16(offset, bitsPerSample, Endian.little); offset += 2;
  writeString('data');
  b.setUint32(offset, dataSize, Endian.little); offset += 4;

  for (var i = 0; i < samples.length; i++) {
    final s = (samples[i] * maxAmp).clamp(-maxAmp, maxAmp).toInt();
    b.setInt16(offset, s, Endian.little);
    offset += 2;
  }

  return data;
}

// ===========================================================================
// SOUND GENERATORS
// ===========================================================================

Float64List _makeSamples(double duration, double Function(double t) generator) {
  final len = (sampleRate * duration).round();
  final result = Float64List(len);
  for (var i = 0; i < len; i++) {
    result[i] = generator(i / sampleRate);
  }
  return result;
}

// Envelope helpers
double _linEnv(double t, double dur, double attack, double release) {
  if (t < attack) return t / attack;
  if (t > dur - release) return (dur - t) / release;
  return 1.0;
}

double _expEnv(double t, double dur, double attack, double release) {
  final l = _linEnv(t, dur, attack, release);
  return l * l; // quadratic = "exponential" feel
}

// Noise
double _noise() => (Random().nextDouble() * 2 - 1);

// --- THEME: dark fantasy cinematic (30s, loopable) ---
Float64List _ambientDrone(double dur) {
  return _makeSamples(dur, (t) {
    // Deep sub-bass drone (slowly modulating)
    final subFreq = 27.5 + sin(t * 0.05) * 3;
    final sub = sin(2 * pi * subFreq * t) * 0.4;

    // Mid bass layer with filter sweep
    final bassFreq = 55.0 + sin(t * 0.08) * 8;
    final bass1 = sin(2 * pi * bassFreq * t) * 0.25;
    final bass2 = sin(2 * pi * bassFreq * 1.5 * t) * 0.12;

    // Dark pad with detune
    final padFreq = 110.0 + sin(t * 0.03) * 2;
    final pad1 = sin(2 * pi * padFreq * t) * 0.15;
    final pad2 = sin(2 * pi * padFreq * 1.01 * t) * 0.12;
    final pad3 = sin(2 * pi * padFreq * 0.99 * t) * 0.12;
    final pad = (pad1 + pad2 + pad3) * (0.5 + sin(t * 0.2) * 0.15);

    // Slow melody using Phrygian mode (E Phrygian: E F G A B C D E)
    final melodyNotes = [82.41, 98.0, 110.0, 130.81, 146.83, 164.81, 196.0];
    final noteIdx = ((t * 0.4).floor()) % melodyNotes.length;
    final glide = t * 0.4 - (t * 0.4).floor();
    final curNote = melodyNotes[noteIdx];
    final nextNote = melodyNotes[(noteIdx + 1) % melodyNotes.length];
    final melFreq = curNote + (nextNote - curNote) * (glide < 0.5 ? glide * 2 : (1 - glide) * 2);
    final melEnv = sin(t * 0.4 * pi) * 0.5;
    final melody = sin(2 * pi * melFreq * t + sin(t * 2) * 0.02) * melEnv * 0.1;

    // Dark ambient texture (filtered noise with slow modulation)
    final noise = _noise() * (0.02 + sin(t * 0.15) * 0.01);
    final filteredNoise = noise * (0.3 + sin(t * 0.1) * 0.2);

    // Slow pulse/ heartbeat
    final pulse = sin(t * pi * 0.5) * 0.06;

    // Gradual build
    final buildEnv = (t / dur).clamp(0.0, 1.0) * 0.3 + 0.7;

    return (sub + bass1 + bass2 + pad + melody + filteredNoise + pulse) * buildEnv * 0.5;
  });
}

// --- SWOOSH ---
Float64List _swoosh(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.01, dur * 0.6);
    final noise = _noise() * env * 0.4;
    final sweep = sin(2 * pi * (200 + t / dur * 2000) * t) * env * 0.3;
    return noise + sweep;
  });
}

// --- JUMP ---
Float64List _jump(double dur) {
  return _makeSamples(dur, (t) {
    final env = _expEnv(t, dur, 0.005, 0.05);
    final freq = 300 + t / dur * 600;
    return sin(2 * pi * freq * t) * env * 0.4;
  });
}

// --- WHOOSH (dash) ---
Float64List _whoosh(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.01, 0.1);
    final noise = _noise() * env * 0.3;
    final s1 = sin(2 * pi * (100 + t / dur * 1500) * t) * env * 0.25;
    final s2 = sin(2 * pi * (80 + t / dur * 800) * t) * env * 0.15;
    return noise + s1 + s2;
  });
}

// --- HURT ---
Float64List _hurt(double dur) {
  return _makeSamples(dur, (t) {
    final env = _expEnv(t, dur, 0.005, dur * 0.4);
    final f1 = sin(2 * pi * 80 * t) * env * 0.5;
    final f2 = sin(2 * pi * 120 * t) * env * 0.3;
    final noise = _noise() * env * 0.2;
    return (f1 + f2 + noise) * 0.6;
  });
}

// --- DEATH ---
Float64List _death(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.02, dur * 0.5);
    final freq = 200 - t / dur * 150;
    final s1 = sin(2 * pi * freq * t) * env * 0.4;
    final s2 = sin(2 * pi * freq * 0.5 * t) * env * 0.2;
    final noise = _noise() * env * 0.1 * (1 - t / dur);
    return (s1 + s2 + noise) * 0.5;
  });
}

// --- CHIME (potion) ---
Float64List _chime(double dur) {
  return _makeSamples(dur, (t) {
    final env = _expEnv(t, dur, 0.005, dur * 0.7);
    final f1 = sin(2 * pi * 880 * t);
    final f2 = sin(2 * pi * 1320 * t) * 0.5;
    final f3 = sin(2 * pi * 1760 * t) * 0.25;
    return (f1 + f2 + f3) * env * 0.35;
  });
}

// --- POWER BURST (skill) ---
Float64List _powerBurst(double dur) {
  return _makeSamples(dur, (t) {
    final env = _expEnv(t, dur, 0.005, dur * 0.5);
    final noise = _noise() * env * 0.5;
    final s1 = sin(2 * pi * (100 + t / dur * 400) * t) * env * 0.4;
    final s2 = sin(2 * pi * 200 * t) * env * 0.3;
    return (noise + s1 + s2) * 0.6;
  });
}

// --- CLANG (block) ---
Float64List _clang(double dur) {
  return _makeSamples(dur, (t) {
    final env = _expEnv(t, dur, 0.001, dur * 0.6);
    final f1 = sin(2 * pi * 800 * t);
    final f2 = sin(2 * pi * 1200 * t) * 0.6;
    final f3 = sin(2 * pi * 1600 * t) * 0.3;
    final noise = _noise() * 0.2;
    return (f1 + f2 + f3 + noise) * env * 0.3;
  });
}

// --- GROWL ---
Float64List _growl(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.01, 0.1);
    final f1 = sin(2 * pi * 60 * t) * 0.3;
    final f2 = sin(2 * pi * 90 * t) * 0.2;
    final noise = _noise() * env * 0.4;
    return (f1 + f2 + noise) * env * 0.5;
  });
}

// --- POP ---
Float64List _pop(double dur) {
  return _makeSamples(dur, (t) {
    final env = _expEnv(t, dur, 0.002, dur * 0.3);
    final noise = _noise() * env * 0.6;
    final f = sin(2 * pi * (200 - t / dur * 150) * t) * env * 0.3;
    return (noise + f) * 0.5;
  });
}

// --- ROAR ---
Float64List _roar(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.05, dur * 0.5);
    final sub = sin(2 * pi * 40 * t) * 0.5;
    final f1 = sin(2 * pi * 80 * t) * 0.4;
    final f2 = sin(2 * pi * 120 * t) * 0.2;
    final noise = _noise() * env * 0.5;
    final wobble = sin(2 * pi * (3 + t * t * 2) * t) * 0.3;
    return (sub + f1 + f2 + noise + wobble) * env * 0.4;
  });
}

// --- HEAVY SWING ---
Float64List _heavySwing(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.01, dur * 0.3);
    final s1 = sin(2 * pi * (80 + t / dur * 300) * t) * env * 0.4;
    final s2 = sin(2 * pi * (60 + t / dur * 200) * t) * env * 0.3;
    final noise = _noise() * env * 0.3;
    return (s1 + s2 + noise) * 0.5;
  });
}

// --- DARK BUILDUP ---
Float64List _darkBuildup(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.05, 0.01);
    final f1 = sin(2 * pi * (50 + t / dur * 100) * t) * 0.3;
    final f2 = sin(2 * pi * (100 + t / dur * 200) * t) * 0.2;
    final noise = _noise() * (0.1 + t / dur * 0.5);
    final pulse = sin(t * 8 * pi) * 0.15;
    return (f1 + f2 + noise + pulse) * env * 0.5;
  });
}

// --- EXPLOSION ---
Float64List _explosion(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.005, dur * 0.7);
    final noise = _noise() * env * 0.7;
    final sub = sin(2 * pi * (30 - t / dur * 20) * t) * env * 0.5;
    final rattle = sin(2 * pi * 200 * t) * _noise() * env * 0.3;
    return (noise + sub + rattle) * 0.5;
  });
}

// --- SCREAM (rage) ---
Float64List _scream(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.02, dur * 0.4);
    final f1 = sin(2 * pi * (200 + t / dur * 800) * t) * env * 0.4;
    final f2 = sin(2 * pi * (400 + t / dur * 1200) * t) * env * 0.3;
    final noise = _noise() * env * 0.5;
    final fm = sin(2 * pi * 5 * t) * 0.2;
    return (f1 + f2 + noise + fm) * 0.5;
  });
}

// --- PICKUP ---
Float64List _pickup(double dur) {
  return _makeSamples(dur, (t) {
    final env = _expEnv(t, dur, 0.002, dur * 0.5);
    final f1 = sin(2 * pi * 1200 * t);
    final f2 = sin(2 * pi * 1600 * t) * 0.5;
    final f3 = sin(2 * pi * 2000 * t) * 0.25;
    return (f1 + f2 + f3) * env * 0.3;
  });
}

// --- CHECKPOINT ---
Float64List _checkpoint(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.1, dur * 0.6);
    final freq = 400 + sin(t * 2 * pi * 3) * 50;
    final f1 = sin(2 * pi * freq * t) * 0.3;
    final f2 = sin(2 * pi * freq * 2 * t) * 0.15;
    final glow = sin(t * 6 * pi) * 0.1 * env;
    return (f1 + f2 + glow) * env * 0.4;
  });
}

// --- PER-LEVEL THEMES ---
Float64List _villageTheme(double dur) {
  final rng = Random(43);
  return _makeSamples(dur, (t) {
    final sub = sin(2 * pi * 27.5 * t) * 0.3;
    final mournful = sin(2 * pi * (65.41 + sin(t * 0.1) * 5) * t) * 0.2;
    final wind = _noise() * 0.03;
    final embers = sin(2 * pi * (200 + rng.nextDouble() * 400) * t) * 0.02;
    return (sub + mournful + wind + embers) * 0.5;
  });
}

Float64List _forestTheme(double dur) {
  return _makeSamples(dur, (t) {
    final drone = sin(2 * pi * 32.7 * t) * 0.25;
    final whisper = sin(2 * pi * (400 + sin(t * 0.3) * 200) * t) * 0.08;
    final wind = _noise() * 0.04;
    final rustle = sin(2 * pi * 8 * t) * 0.03;
    return (drone + whisper + wind + rustle) * 0.5;
  });
}

Float64List _castleTheme(double dur) {
  return _makeSamples(dur, (t) {
    final drone = sin(2 * pi * 29.0 * t) * 0.3;
    final organ = sin(2 * pi * (98.0 + sin(t * 0.05) * 10) * t) * 0.15;
    final chime = sin(2 * pi * 440 * t) * (sin(t * 0.5) * 0.5 + 0.5) * 0.04;
    final reverb = _noise() * (0.02 + sin(t * 0.2) * 0.01);
    return (drone + organ + chime + reverb) * 0.5;
  });
}

Float64List _abyssTheme(double dur) {
  return _makeSamples(dur, (t) {
    final sub = sin(2 * pi * 20.0 * t) * 0.35;
    final growl = sin(2 * pi * (40 + sin(t * 0.2) * 15) * t) * 0.2;
    final scream = sin(2 * pi * (800 + sin(t * 0.7) * 400) * t) * 0.03;
    final chaos = _noise() * (0.03 + sin(t * 0.5) * 0.02);
    final heartbeat = (sin(t * pi * 2) > 0.95 ? 1.0 : 0.0) * 0.1;
    return (sub + growl + scream + chaos + heartbeat) * 0.5;
  });
}

// --- BOSS THEME ---
Float64List _bossTheme(double dur) {
  return _makeSamples(dur, (t) {
    final sub = sin(2 * pi * 30.0 * t) * 0.35;
    final warDrums = (sin(t * 8 * pi * 2) > 0.7 ? sin(2 * pi * 60 * t) * 0.2 : 0.0);
    final brass = sin(2 * pi * (110 + sin(t * 0.2) * 20) * t) * 0.15;
    final tension = sin(2 * pi * (400 + sin(t * 2) * 200) * t) * (0.1 + sin(t * 0.5) * 0.06);
    final chaos = _noise() * (0.05 + sin(t) * 0.03);
    return (sub + warDrums + brass + tension + chaos) * 0.5;
  });
}

// --- LONG FADE (boss death) ---
Float64List _longFade(double dur) {
  return _makeSamples(dur, (t) {
    final env = _linEnv(t, dur, 0.02, dur * 0.8);
    final freq = 100 - t / dur * 80;
    final f1 = sin(2 * pi * freq * t) * 0.3;
    final f2 = sin(2 * pi * freq * 1.5 * t) * 0.15;
    final f3 = sin(2 * pi * freq * 0.5 * t) * 0.2;
    final noise = _noise() * (0.2 - t / dur * 0.15);
    return (f1 + f2 + f3 + noise) * env * 0.4;
  });
}
