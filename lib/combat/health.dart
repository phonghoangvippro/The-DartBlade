import 'dart:math';

/// Reusable health pool with change notifications.
class Health {
  Health(this.max) : current = max;

  double max;
  double current;

  bool get isDead => current <= 0;
  bool get isFull => current >= max;
  double get ratio => max <= 0 ? 0 : (current / max).clamp(0.0, 1.0);

  /// Applies damage, returns actual amount dealt.
  double damage(double amount) {
    final dealt = min(current, amount);
    current = max2(0, current - amount);
    return dealt;
  }

  void heal(double amount) {
    current = min(max, current + amount);
  }

  void refill() => current = max;

  static double max2(double a, double b) => a > b ? a : b;
}
