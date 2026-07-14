import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/save/save_model.dart';

void main() {
  group('SaveModel (FR-031, FR-032)', () {
    test('serializes and deserializes symmetrically', () {
      final model = SaveModel(
        currentLevel: 2,
        playerX: 123.5,
        playerY: 456.0,
        hp: 77,
        mana: 30,
        stamina: 88,
        souls: 420,
        inventoryJson: {
          'stacks': [
            {'id': 'health_potion', 'count': 2},
          ],
          'weapon': 'iron_sword',
          'armor': null,
        },
        defeatedBosses: [0],
      );

      final restored = SaveModel.fromJson(model.toJson());

      expect(restored.currentLevel, 2);
      expect(restored.playerX, 123.5);
      expect(restored.playerY, 456.0);
      expect(restored.hp, 77);
      expect(restored.souls, 420);
      expect(restored.defeatedBosses, [0]);
      expect(restored.inventoryJson['weapon'], 'iron_sword');
    });

    test('tolerates missing fields with safe defaults', () {
      final restored = SaveModel.fromJson({});
      expect(restored.currentLevel, 0);
      expect(restored.hp, 100);
      expect(restored.souls, 0);
      expect(restored.defeatedBosses, isEmpty);
    });
  });
}
