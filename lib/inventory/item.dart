import 'dart:ui';

/// Categories of items (FR-028..FR-030).
enum ItemType { consumable, weapon, armor, keyItem }

/// Immutable item definition. Instances in the inventory reference these.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.healAmount = 0,
    this.color = const Color(0xFFBDBDBD),
    this.stackable = false,
  });

  final String id;
  final String name;
  final ItemType type;
  final String description;
  final double attackBonus;
  final double defenseBonus;
  final double healAmount;
  final Color color;
  final bool stackable;

  bool get isEquippable =>
      type == ItemType.weapon || type == ItemType.armor;

  // ------------------------------------------------------------ definitions
  static const healthPotion = Item(
    id: 'health_potion',
    name: 'Health Potion',
    type: ItemType.consumable,
    description: 'Restores 40 HP.',
    healAmount: 40,
    color: Color(0xFFE05252),
    stackable: true,
  );

  static const ironSword = Item(
    id: 'iron_sword',
    name: 'Iron Sword',
    type: ItemType.weapon,
    description: '+6 Attack.',
    attackBonus: 6,
    color: Color(0xFF9FB4C7),
  );

  static const cursedBlade = Item(
    id: 'cursed_blade',
    name: 'Cursed Blade',
    type: ItemType.weapon,
    description: '+14 Attack. Whispers in the dark.',
    attackBonus: 14,
    color: Color(0xFF9C4DF4),
  );

  static const knightArmor = Item(
    id: 'knight_armor',
    name: 'Knight Armor',
    type: ItemType.armor,
    description: '+5 Defense.',
    defenseBonus: 5,
    color: Color(0xFF8D99AE),
  );

  static const darkbladeShard = Item(
    id: 'darkblade_shard',
    name: 'Darkblade Shard',
    type: ItemType.keyItem,
    description: 'A fragment of the legendary blade.',
    color: Color(0xFF7B2FF2),
  );

  /// Registry used by the save system to restore items by id.
  static const Map<String, Item> registry = {
    'health_potion': healthPotion,
    'iron_sword': ironSword,
    'cursed_blade': cursedBlade,
    'knight_armor': knightArmor,
    'darkblade_shard': darkbladeShard,
  };
}
