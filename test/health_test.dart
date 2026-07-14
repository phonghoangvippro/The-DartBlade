import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/combat/health.dart';

void main() {
  group('Health', () {
    test('damage reduces current HP and clamps at 0', () {
      final hp = Health(100);
      hp.damage(30);
      expect(hp.current, 70);
      hp.damage(999);
      expect(hp.current, 0);
      expect(hp.isDead, isTrue);
    });

    test('heal never exceeds max', () {
      final hp = Health(100);
      hp.damage(50);
      hp.heal(999);
      expect(hp.current, 100);
    });

    test('ratio reflects current/max', () {
      final hp = Health(200);
      hp.damage(50);
      expect(hp.ratio, closeTo(0.75, 0.0001));
    });
  });
}
