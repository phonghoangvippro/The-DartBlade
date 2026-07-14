import 'package:flutter/material.dart';

import '../game/darkblade_game.dart';
import '../inventory/inventory.dart';
import '../inventory/item.dart';

/// Inventory overlay (FR-035): list items, equip weapons/armor, drink potions.
class InventoryMenu extends StatelessWidget {
  const InventoryMenu({super.key, required this.game});

  final DarkbladeGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16121E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF7B2FF2)),
          ),
          child: AnimatedBuilder(
            animation: game.inventory,
            builder: (context, _) {
              final inv = game.inventory;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'INVENTORY',
                        style: TextStyle(
                          color: Color(0xFFB388FF),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: game.togglePause,
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  _equipmentRow(inv),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 4),
                  if (inv.stacks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('Your pack is empty...',
                            style: TextStyle(color: Colors.white38)),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final stack in inv.stacks)
                            _itemTile(context, stack.item, stack.count),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Attack: ${game.player.stats.attack.toStringAsFixed(0)}'
                    '   Defense: ${game.player.stats.defense.toStringAsFixed(0)}'
                    '   Souls: ${game.player.stats.souls}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _equipmentRow(Inventory inv) {
    return Row(
      children: [
        _equipSlot('WEAPON', inv.equippedWeapon),
        const SizedBox(width: 16),
        _equipSlot('ARMOR', inv.equippedArmor),
      ],
    );
  }

  Widget _equipSlot(String label, Item? item) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: item != null
                  ? const Color(0xFF7B2FF2)
                  : Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              item?.name ?? '- empty -',
              style: TextStyle(
                color: item != null ? item.color : Colors.white24,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(BuildContext context, Item item, int count) {
    final inv = game.inventory;
    final isEquipped =
        inv.equippedWeapon == item || inv.equippedArmor == item;

    return ListTile(
      dense: true,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: item.color),
        ),
        child: Icon(
          switch (item.type) {
            ItemType.consumable => Icons.local_drink,
            ItemType.weapon => Icons.gavel,
            ItemType.armor => Icons.shield,
            ItemType.keyItem => Icons.vpn_key,
          },
          size: 15,
          color: item.color,
        ),
      ),
      title: Text(
        count > 1 ? '${item.name}  x$count' : item.name,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      subtitle: Text(
        item.description,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      trailing: _actionButton(item, isEquipped),
    );
  }

  Widget? _actionButton(Item item, bool isEquipped) {
    if (item.type == ItemType.consumable) {
      return TextButton(
        onPressed: () {
          game.useEquippedPotion();
        },
        child: const Text('USE',
            style: TextStyle(color: Color(0xFF45D67E), fontSize: 12)),
      );
    }
    if (item.isEquippable) {
      return TextButton(
        onPressed: () {
          if (isEquipped) {
            game.inventory.unequip(item.type);
          } else {
            game.inventory.equip(item);
          }
          game.refreshEquipment();
        },
        child: Text(
          isEquipped ? 'UNEQUIP' : 'EQUIP',
          style: TextStyle(
            color: isEquipped
                ? Colors.white38
                : const Color(0xFFB388FF),
            fontSize: 12,
          ),
        ),
      );
    }
    return null;
  }
}
