import '../core/config/game_config.dart';
import '../core/utils/math_utils.dart';

/// Player resource pools & progression numbers (HP is on [Character]).
class PlayerStats {
  double maxMana = GameConfig.playerMaxMana;
  double mana = GameConfig.playerMaxMana;

  double maxStamina = GameConfig.playerMaxStamina;
  double stamina = GameConfig.playerMaxStamina;

  double baseAttack = GameConfig.playerAttack;
  double baseDefense = GameConfig.playerDefense;

  /// Currency dropped by enemies (souls-like).
  int souls = 0;

  /// Bonuses granted by equipped items.
  double equipmentAttackBonus = 0;
  double equipmentDefenseBonus = 0;

  double get attack => baseAttack + equipmentAttackBonus;
  double get defense => baseDefense + equipmentDefenseBonus;

  double get manaRatio => maxMana <= 0 ? 0 : mana / maxMana;
  double get staminaRatio => maxStamina <= 0 ? 0 : stamina / maxStamina;

  bool spendStamina(double amount) {
    if (stamina < amount) return false;
    stamina -= amount;
    return true;
  }

  bool spendMana(double amount) {
    if (mana < amount) return false;
    mana -= amount;
    return true;
  }

  void regenerate(double dt) {
    stamina = MathUtils.clampDouble(
      stamina + GameConfig.staminaRegen * dt,
      0,
      maxStamina,
    );
    mana = MathUtils.clampDouble(mana + GameConfig.manaRegen * dt, 0, maxMana);
  }
}
