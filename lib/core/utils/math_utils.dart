import 'dart:math';
import 'dart:ui';

/// Small math helpers shared across the game.
class MathUtils {
  MathUtils._();

  static final Random rng = Random();

  /// Moves [current] towards [target] by at most [maxDelta].
  static double approach(double current, double target, double maxDelta) {
    if (current < target) return min(current + maxDelta, target);
    if (current > target) return max(current - maxDelta, target);
    return target;
  }

  static double clampDouble(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  static bool rectsOverlap(Rect a, Rect b) => a.overlaps(b);

  /// Random value in [min, max).
  static double range(double min, double max) =>
      min + rng.nextDouble() * (max - min);
}
