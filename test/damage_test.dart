import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/combat/damage.dart';

/// Deterministic Random for testing crit branches.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  int nextInt(int max) => (value * max).floor();
}

void main() {
  group('DamageCalculator', () {
    test('basic formula: attack * multiplier - defense', () {
      final calc = DamageCalculator(random: _FixedRandom(0.99)); // no crit
      final result = calc.calculate(
        attack: 20,
        skillMultiplier: 1.5,
        defense: 5,
      );
      expect(result.amount, 25); // 20*1.5 - 5
      expect(result.isCritical, isFalse);
    });

    test('critical hit doubles damage (5% chance branch)', () {
      final calc = DamageCalculator(random: _FixedRandom(0.01)); // crit
      final result = calc.calculate(attack: 10, defense: 0);
      expect(result.isCritical, isTrue);
      expect(result.amount, 20); // 10 * 2
    });

    test('no crit when canCrit is false', () {
      final calc = DamageCalculator(random: _FixedRandom(0.0));
      final result = calc.calculate(attack: 10, canCrit: false);
      expect(result.isCritical, isFalse);
      expect(result.amount, 10);
    });

    test('minimum damage is 1 even with huge defense', () {
      final calc = DamageCalculator(random: _FixedRandom(0.99));
      final result = calc.calculate(attack: 5, defense: 100);
      expect(result.amount, 1);
    });

    test('blocking reduces damage by 70%', () {
      final calc = DamageCalculator(random: _FixedRandom(0.99));
      final result = calc.calculate(
        attack: 100,
        defense: 0,
        targetBlocking: true,
      );
      expect(result.blocked, isTrue);
      expect(result.amount, closeTo(30, 0.001));
    });
  });
}
