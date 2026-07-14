import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/combat/combo_tracker.dart';

void main() {
  group('ComboTracker (FR-004, FR-014)', () {
    test('chains attack 1 -> 2 -> 3', () {
      final combo = ComboTracker();
      expect(combo.registerAttack(), 1);
      expect(combo.registerAttack(), 2);
      expect(combo.registerAttack(), 3);
    });

    test('wraps to 1 after the third attack', () {
      final combo = ComboTracker();
      combo
        ..registerAttack()
        ..registerAttack()
        ..registerAttack();
      expect(combo.registerAttack(), 1);
    });

    test('resets when the combo timer expires', () {
      final combo = ComboTracker(resetTime: 0.5);
      combo.registerAttack();
      combo.registerAttack();
      combo.update(0.6); // exceed reset time
      expect(combo.step, 0);
      expect(combo.registerAttack(), 1);
    });

    test('does not reset while attacks keep coming', () {
      final combo = ComboTracker(resetTime: 0.5);
      combo.registerAttack();
      combo.update(0.3);
      combo.registerAttack();
      combo.update(0.3);
      expect(combo.step, 2);
    });

    test('multiplier grows with combo step', () {
      final combo = ComboTracker();
      combo.registerAttack();
      final m1 = combo.multiplier;
      combo.registerAttack();
      final m2 = combo.multiplier;
      combo.registerAttack();
      final m3 = combo.multiplier;
      expect(m2, greaterThan(m1));
      expect(m3, greaterThan(m2));
    });
  });
}
