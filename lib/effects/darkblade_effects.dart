import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import '../core/constants/game_constants.dart';

class DarkbladeTrail extends Component {
  final List<_TrailPoint> _points = [];
  final Color _color;
  final double _life;
  final double _width;

  DarkbladeTrail({
    required Vector2 start,
    required Vector2 direction,
    Color color = const Color(0xFF7B2FF2),
    double life = 0.3,
    double width = 6,
  }) : _color = color,
       _life = life,
       _width = width {
    _points.add(_TrailPoint(start, _life));
  }

  void addPoint(Vector2 pos) {
    _points.add(_TrailPoint(pos, _life));
    if (_points.length > 12) _points.removeAt(0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _points) {
      p.life -= dt;
    }
    _points.removeWhere((p) => p.life <= 0);
    if (_points.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_points.length < 2) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < _points.length; i++) {
      final ratio = (i / _points.length).clamp(0.0, 1.0);
      paint.color = _color.withValues(
        alpha: _points[i].life / _life * 0.6 * ratio,
      );
      canvas.drawLine(
        Offset(_points[i - 1].pos.x, _points[i - 1].pos.y),
        Offset(_points[i].pos.x, _points[i].pos.y),
        paint,
      );
    }
  }
}

class _TrailPoint {
  Vector2 pos;
  double life;
  _TrailPoint(this.pos, this.life);
}

class DarkbladeAura extends PositionComponent {
  final double _radius;
  final Color _color;
  double _timer = 0;

  DarkbladeAura({
    required super.position,
    double radius = 40,
    Color color = const Color(0xFF7B2FF2),
  }) : _radius = radius,
       _color = color {
    priority = GameConstants.priorityFx;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = sin(_timer * 4) * 0.15 + 0.85;
    final paint1 = Paint()..color = _color.withValues(alpha: 0.08 * pulse);
    canvas.drawCircle(Offset.zero, _radius * pulse, paint1);
    final paint2 = Paint()..color = _color.withValues(alpha: 0.04);
    canvas.drawCircle(Offset.zero, _radius * 1.6 * pulse, paint2);
  }
}

class DarkEnergyBurst extends PositionComponent {
  final Color _color;
  double _timer = 0;
  final double _duration;
  final double _maxRadius;
  final double _startRadius;

  DarkEnergyBurst({
    required super.position,
    Color color = const Color(0xFF7B2FF2),
    double duration = 0.4,
    double maxRadius = 60,
    double startRadius = 5,
  }) : _color = color,
       _duration = duration,
       _maxRadius = maxRadius,
       _startRadius = startRadius {
    priority = GameConstants.priorityFx;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_timer / _duration).clamp(0.0, 1.0);
    final radius = _startRadius + (_maxRadius - _startRadius) * progress;
    final alpha = (1 - progress) * 0.6;
    final paint = Paint()..color = _color.withValues(alpha: alpha);
    canvas.drawCircle(Offset.zero, radius, paint);
    final paint2 = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.5);
    canvas.drawCircle(Offset.zero, radius * 0.3, paint2);
  }
}

class HitSparks extends PositionComponent {
  final List<_Spark> _sparks = [];
  final Random _rng = Random();

  HitSparks({
    required super.position,
    Color color = const Color(0xFFFFA726),
    int count = 8,
  }) {
    priority = GameConstants.priorityFx;
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 80 + _rng.nextDouble() * 200;
      _sparks.add(
        _Spark(
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          life: 0.2 + _rng.nextDouble() * 0.3,
          size: 1.5 + _rng.nextDouble() * 2.5,
          color: _rng.nextDouble() > 0.5 ? color : const Color(0xFFFFFFFF),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final s in _sparks) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 400 * dt;
      s.life -= dt;
    }
    _sparks.removeWhere((s) => s.life <= 0);
    if (_sparks.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final s in _sparks) {
      paint.color = s.color.withValues(alpha: (s.life / 0.5).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(s.x, s.y), s.size, paint);
    }
  }
}

class _Spark {
  double x = 0, y = 0, vx, vy, life, size;
  Color color;
  _Spark({
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
  });
}

class BloodSpatter extends PositionComponent {
  final List<_BloodDrop> _drops = [];
  final Random _rng = Random();
  final Paint _paint = Paint();
  double _life = 0.8;

  BloodSpatter({required super.position, int count = 10}) {
    priority = GameConstants.priorityFx;
    for (var i = 0; i < count; i++) {
      _drops.add(
        _BloodDrop(
          x: (_rng.nextDouble() - 0.5) * 20,
          y: (_rng.nextDouble() - 0.5) * 10,
          size: 2 + _rng.nextDouble() * 4,
          alpha: 0.6 + _rng.nextDouble() * 0.4,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (_life / 0.8).clamp(0.0, 1.0);
    for (final d in _drops) {
      _paint.color = const Color(0xFF8B0000).withValues(alpha: d.alpha * fade);
      canvas.drawCircle(Offset(d.x, d.y), d.size, _paint);
    }
  }
}

class _BloodDrop {
  double x, y, size, alpha;
  _BloodDrop({
    required this.x,
    required this.y,
    required this.size,
    required this.alpha,
  });
}
