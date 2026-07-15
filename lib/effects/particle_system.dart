import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

class Particle {
  double x, y;
  double vx, vy;
  double life, maxLife;
  double size;
  Color color;
  double alpha;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
    this.alpha = 1.0,
  });

  bool get isDead => life <= 0;
  double get ratio => (life / maxLife).clamp(0.0, 1.0);
}

class ParticleEmitter extends PositionComponent
    with HasGameReference<DarkbladeGame> {
  final EmitterConfig config;
  final List<Particle> _particles = [];
  final Random _rng = Random();
  final Paint _paint = Paint();
  double _timer = 0;

  ParticleEmitter({required this.config, Vector2? position})
    : super(position: position ?? Vector2.zero()) {
    priority = GameConstants.priorityFx;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    while (_timer >= config.emitInterval &&
        _particles.length < config.maxParticles) {
      _emit();
      _timer -= config.emitInterval;
    }
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += config.gravity * dt;
      p.life -= dt;
      p.alpha = p.ratio;
    }
    _particles.removeWhere((p) => p.isDead);
    if (_particles.isEmpty && config.oneshot) removeFromParent();
  }

  void _emit() {
    for (var i = 0; i < config.burstCount; i++) {
      final angle = config.angleSpread > 0
          ? config.baseAngle + (_rng.nextDouble() - 0.5) * config.angleSpread
          : config.baseAngle;
      final speed =
          config.minSpeed +
          _rng.nextDouble() * (config.maxSpeed - config.minSpeed);
      _particles.add(
        Particle(
          x: position.x + (_rng.nextDouble() - 0.5) * config.spreadX,
          y: position.y + (_rng.nextDouble() - 0.5) * config.spreadY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          life:
              config.minLife +
              _rng.nextDouble() * (config.maxLife - config.minLife),
          maxLife: config.maxLife,
          size:
              config.minSize +
              _rng.nextDouble() * (config.maxSize - config.minSize),
          color: config.color,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final stride = game.lowFpsMode ? 2 : 1;
    for (var i = 0; i < _particles.length; i += stride) {
      final p = _particles[i];
      _paint
        ..color = p.color.withValues(alpha: p.alpha * config.opacity)
        ..maskFilter = null;
      canvas.drawCircle(Offset(p.x, p.y), p.size, _paint);
    }
  }
}

class EmitterConfig {
  final double emitInterval;
  final int burstCount;
  final int maxParticles;
  final double baseAngle;
  final double angleSpread;
  final double minSpeed;
  final double maxSpeed;
  final double minLife;
  final double maxLife;
  final double minSize;
  final double maxSize;
  final double spreadX;
  final double spreadY;
  final Color color;
  final double opacity;
  final double gravity;
  final bool oneshot;

  const EmitterConfig({
    this.emitInterval = 0.05,
    this.burstCount = 1,
    this.maxParticles = 40,
    this.baseAngle = -pi / 2,
    this.angleSpread = 0.5,
    this.minSpeed = 30,
    this.maxSpeed = 80,
    this.minLife = 0.4,
    this.maxLife = 1.2,
    this.minSize = 1.5,
    this.maxSize = 4,
    this.spreadX = 0,
    this.spreadY = 0,
    this.color = const Color(0xFFFFFFFF),
    this.opacity = 0.8,
    this.gravity = 0,
    this.oneshot = false,
  });
}

class DarkMistEffect extends Component with HasGameReference<DarkbladeGame> {
  final List<_MistParticle> _particles = [];
  final Random _rng = Random();
  final double _width;
  final double _height;
  final Color _color;
  final Paint _outerPaint = Paint();
  final Paint _innerPaint = Paint();

  DarkMistEffect(this._width, this._height, this._color) {
    for (var i = 0; i < 7; i++) {
      final size = 28 + _rng.nextDouble() * 36;
      final alpha = 0.04 + _rng.nextDouble() * 0.08;
      _particles.add(
        _MistParticle(
          x: _rng.nextDouble() * _width,
          y: _rng.nextDouble() * _height,
          size: size,
          speed: 5 + _rng.nextDouble() * 15,
          alpha: alpha,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _particles) {
      p.x += p.speed * dt;
      if (p.x > _width + p.size) p.x = -p.size;
    }
  }

  @override
  void render(Canvas canvas) {
    final playerX = game.playerReady ? game.player.absoluteCenter.x : 0.0;
    final stride = game.lowFpsMode ? 2 : 1;
    for (var i = 0; i < _particles.length; i += stride) {
      final p = _particles[i];
      if (game.playerReady && (p.x - playerX).abs() > 650) continue;
      _outerPaint.color = _color.withValues(alpha: p.alpha * 0.3);
      canvas.drawCircle(Offset(p.x, p.y), p.size, _outerPaint);
      _innerPaint.color = _color.withValues(alpha: p.alpha * 0.55);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.62, _innerPaint);
    }
  }
}

class _MistParticle {
  double x, y, size, speed, alpha;
  _MistParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.alpha,
  });
}

class RainEffect extends Component with HasGameReference<DarkbladeGame> {
  final List<_RainDrop> _drops = [];
  final Random _rng = Random();
  final double _width;
  final double _height;
  final Paint _paint = Paint();

  RainEffect(this._width, this._height) {
    for (var i = 0; i < 48; i++) {
      _resetDrop(i % 2 == 0);
    }
  }

  void _resetDrop([bool init = false]) {
    _drops.add(
      _RainDrop(
        x: _rng.nextDouble() * _width,
        y: init ? _rng.nextDouble() * _height : -10,
        length: 8 + _rng.nextDouble() * 12,
        speed: 300 + _rng.nextDouble() * 200,
        alpha: 0.2 + _rng.nextDouble() * 0.3,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final d in _drops) {
      d.y += d.speed * dt;
      d.x += 40 * dt;
      if (d.y > _height || d.x > _width) {
        d.x = _rng.nextDouble() * _width;
        d.y = -d.length;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final stride = game.lowFpsMode ? 3 : 1;
    for (var i = 0; i < _drops.length; i += stride) {
      final d = _drops[i];
      _paint.color = const Color(0xAA7B9DB5).withValues(alpha: d.alpha);
      canvas.drawLine(
        Offset(d.x, d.y),
        Offset(d.x - 3, d.y - d.length),
        _paint,
      );
    }
  }
}

class _RainDrop {
  double x, y, length, speed, alpha;
  _RainDrop({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.alpha,
  });
}

class AshFallEffect extends Component with HasGameReference<DarkbladeGame> {
  final List<_AshParticle> _particles = [];
  final Random _rng = Random();
  final double _width;
  final double _height;
  final Paint _paint = Paint();

  AshFallEffect(this._width, this._height) {
    for (var i = 0; i < 22; i++) {
      _particles.add(
        _AshParticle(
          x: _rng.nextDouble() * _width,
          y: _rng.nextDouble() * _height,
          size: 1 + _rng.nextDouble() * 3,
          speedY: 20 + _rng.nextDouble() * 40,
          speedX: -5 + _rng.nextDouble() * 10,
          alpha: 0.3 + _rng.nextDouble() * 0.4,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _particles) {
      p.x += p.speedX * dt;
      p.y += p.speedY * dt;
      if (p.y > _height) {
        p.y = -5;
        p.x = _rng.nextDouble() * _width;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final stride = game.lowFpsMode ? 3 : 1;
    for (var i = 0; i < _particles.length; i += stride) {
      final p = _particles[i];
      _paint.color = const Color(0xFF888888).withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.size, _paint);
    }
  }
}

class _AshParticle {
  double x, y, size, speedY, speedX, alpha;
  _AshParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.alpha,
  });
}
