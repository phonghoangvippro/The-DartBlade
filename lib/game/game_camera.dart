import 'dart:math';

import 'package:flame/components.dart';

import '../core/utils/math_utils.dart';

/// Camera controller (plan section 13): smooth follow with a dead-zone,
/// world-bounds clamping and screen shake.
class GameCameraController {
  GameCameraController(this.camera);

  final CameraComponent camera;

  PositionComponent? target;
  Vector2 worldSize = Vector2(2000, 640);

  static const double deadZoneWidth = 60;
  static const double followLerp = 5.0;

  double _shakeTime = 0;
  double _shakeIntensity = 0;
  final Random _rng = Random();

  void follow(PositionComponent component) {
    target = component;
    camera.viewfinder.position = component.absoluteCenter.clone();
  }

  void shake({double intensity = 6, double duration = 0.4}) {
    _shakeIntensity = intensity;
    _shakeTime = duration;
  }

  void update(double dt) {
    final t = target;
    if (t == null) return;

    final viewSize = camera.viewport.virtualSize;
    final halfW = viewSize.x / 2;
    final halfH = viewSize.y / 2;

    final current = camera.viewfinder.position.clone();
    final desired = t.absoluteCenter;

    // Dead zone on X: only move when target leaves the middle band.
    var targetX = current.x;
    final dx = desired.x - current.x;
    if (dx.abs() > deadZoneWidth) {
      targetX = desired.x - deadZoneWidth * dx.sign;
    }
    final targetY = desired.y - 40; // bias upward a little

    var newX = current.x + (targetX - current.x) * followLerp * dt;
    var newY = current.y + (targetY - current.y) * followLerp * dt;

    // Clamp to world bounds.
    newX = MathUtils.clampDouble(newX, halfW, max(halfW, worldSize.x - halfW));
    newY = MathUtils.clampDouble(newY, halfH, max(halfH, worldSize.y - halfH));

    // Screen shake.
    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final falloff = (_shakeTime).clamp(0, 1);
      newX += (_rng.nextDouble() * 2 - 1) * _shakeIntensity * falloff;
      newY += (_rng.nextDouble() * 2 - 1) * _shakeIntensity * falloff;
    }

    camera.viewfinder.position = Vector2(newX, newY);
  }
}
