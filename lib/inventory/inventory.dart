import 'package:flutter/foundation.dart';

import 'item.dart';

/// A stack of items in the inventory.
class ItemStack {
  ItemStack(this.item, [this.count = 1]);

  final Item item;
  int count;
}

/// Player inventory + equipment (FR-028, FR-029, FR-030).
///
/// Extends [ChangeNotifier] so Flutter overlay UIs rebuild automatically.
class Inventory extends ChangeNotifier {
  final List<ItemStack> _stacks = [];

  Item? equippedWeapon;
  Item? equippedArmor;

  List<ItemStack> get stacks => List.unmodifiable(_stacks);

  double get attackBonus => equippedWeapon?.attackBonus ?? 0;
  double get defenseBonus => equippedArmor?.defenseBonus ?? 0;

  int countOf(String itemId) => _stacks
      .where((s) => s.item.id == itemId)
      .fold(0, (sum, s) => sum + s.count);

  /// FR-028: add a picked-up item.
  void addItem(Item item, [int count = 1]) {
    if (item.stackable) {
      final existing = _stacks.where((s) => s.item.id == item.id).toList();
      if (existing.isNotEmpty) {
        existing.first.count += count;
        notifyListeners();
        return;
      }
    }
    for (var i = 0; i < count; i++) {
      _stacks.add(ItemStack(item, item.stackable ? count : 1));
      if (item.stackable) break;
    }
    notifyListeners();
  }

  bool removeItem(String itemId, [int count = 1]) {
    for (final stack in _stacks) {
      if (stack.item.id != itemId) continue;
      if (stack.count < count) return false;
      stack.count -= count;
      if (stack.count <= 0) _stacks.remove(stack);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// FR-029: equip a weapon or armor from the inventory.
  bool equip(Item item) {
    if (!item.isEquippable || countOf(item.id) == 0) return false;
    if (item.type == ItemType.weapon) {
      equippedWeapon = item;
    } else {
      equippedArmor = item;
    }
    notifyListeners();
    return true;
  }

  void unequip(ItemType type) {
    if (type == ItemType.weapon) equippedWeapon = null;
    if (type == ItemType.armor) equippedArmor = null;
    notifyListeners();
  }

  /// FR-030: consume a potion; returns heal amount or null if none left.
  double? usePotion() {
    if (!removeItem(Item.healthPotion.id)) return null;
    return Item.healthPotion.healAmount;
  }

  void clear() {
    _stacks.clear();
    equippedWeapon = null;
    equippedArmor = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------- save
  Map<String, dynamic> toJson() => {
    'stacks': [
      for (final s in _stacks) {'id': s.item.id, 'count': s.count},
    ],
    'weapon': equippedWeapon?.id,
    'armor': equippedArmor?.id,
  };

  void restoreFromJson(Map<String, dynamic> json) {
    _stacks.clear();
    for (final raw in (json['stacks'] as List? ?? [])) {
      final map = Map<String, dynamic>.from(raw as Map);
      final item = Item.registry[map['id']];
      if (item != null) {
        _stacks.add(ItemStack(item, (map['count'] as num).toInt()));
      }
    }
    equippedWeapon = Item.registry[json['weapon']];
    equippedArmor = Item.registry[json['armor']];
    notifyListeners();
  }
}
