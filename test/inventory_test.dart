import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/inventory/inventory.dart';
import 'package:the_darkblade/inventory/item.dart';

void main() {
  group('Inventory (FR-028..FR-030)', () {
    test('stackable items merge into one stack', () {
      final inv = Inventory();
      inv.addItem(Item.healthPotion, 2);
      inv.addItem(Item.healthPotion);
      expect(inv.countOf('health_potion'), 3);
      expect(inv.stacks.length, 1);
    });

    test('non-stackable items occupy separate slots', () {
      final inv = Inventory();
      inv.addItem(Item.ironSword);
      inv.addItem(Item.ironSword);
      expect(inv.stacks.length, 2);
    });

    test('equipping a weapon grants attack bonus', () {
      final inv = Inventory();
      inv.addItem(Item.ironSword);
      expect(inv.equip(Item.ironSword), isTrue);
      expect(inv.attackBonus, Item.ironSword.attackBonus);
    });

    test('cannot equip an item not in the inventory', () {
      final inv = Inventory();
      expect(inv.equip(Item.cursedBlade), isFalse);
    });

    test('usePotion consumes one and returns heal amount', () {
      final inv = Inventory();
      inv.addItem(Item.healthPotion, 2);
      final heal = inv.usePotion();
      expect(heal, Item.healthPotion.healAmount);
      expect(inv.countOf('health_potion'), 1);
    });

    test('usePotion returns null when no potions left', () {
      final inv = Inventory();
      expect(inv.usePotion(), isNull);
    });

    test('round-trips through JSON (save/load)', () {
      final inv = Inventory();
      inv.addItem(Item.healthPotion, 3);
      inv.addItem(Item.knightArmor);
      inv.equip(Item.knightArmor);

      final json = inv.toJson();
      final restored = Inventory()..restoreFromJson(json);

      expect(restored.countOf('health_potion'), 3);
      expect(restored.equippedArmor, Item.knightArmor);
      expect(restored.defenseBonus, Item.knightArmor.defenseBonus);
    });
  });
}
