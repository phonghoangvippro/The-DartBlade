/// Central gameplay tuning values for The Darkblade.
///
/// Every "magic number" that affects game feel lives here so the game can be
/// balanced from a single file (week 14 - balancing phase).
class GameConfig {
  GameConfig._();

  // ---------------------------------------------------------------- Physics
  static const double gravity = 1500;
  static const double maxFallSpeed = 900;

  // ----------------------------------------------------------------- Player
  static const double walkSpeed = 160;
  static const double runSpeed = 250;
  static const double jumpVelocity = -540;
  static const double coyoteTime = 0.10;

  static const double playerMaxHp = 100;
  static const double playerMaxMana = 50;
  static const double playerMaxStamina = 100;
  static const double playerAttack = 18;
  static const double playerDefense = 4;

  // ------------------------------------------------------------------- Dash
  static const double dashSpeed = 520;
  static const double dashDuration = 0.18; // also the invincibility window
  static const double dashCooldown = 0.9;
  static const double dashStaminaCost = 20;

  // ----------------------------------------------------------------- Combat
  static const double attackDuration = 0.32;
  static const double attackHitStart = 0.08; // active hit frame window start
  static const double attackHitEnd = 0.22; //   and end (seconds into swing)
  static const double attackStaminaCost = 10;
  static const double comboResetTime = 0.9; // FR-014 combo timer
  static const int maxCombo = 3;
  static const List<double> comboMultipliers = [1.0, 1.15, 1.5];
  static const double meleeRangeX = 52;
  static const double meleeRangeY = 44;

  static const double critChance = 0.05; // 5 % (plan section 8)
  static const double critMultiplier = 2.0;

  static const double blockDamageReduction = 0.7; // FR-015
  static const double blockStaminaFactor = 0.8;

  static const double hurtInvincibleTime = 0.6;
  static const double knockbackX = 170;
  static const double knockbackY = -140;

  // -------------------------------------------------------------- Resources
  static const double staminaRegen = 24; // per second
  static const double manaRegen = 4; // per second

  // ------------------------------------------------------------------ Skill
  static const double skillManaCost = 25; // Blade Wave (FR-018)
  static const double skillMultiplier = 1.4;
  static const double skillCooldown = 3.0;
  static const double skillProjectileSpeed = 420;

  // ------------------------------------------------------------------ Items
  static const double potionHeal = 40; // FR-030

  // --------------------------------------------------------------------- AI
  static const double defaultDetectRange = 150; // plan section 10
  static const double defaultAttackRange = 40;

  // ------------------------------------------------------------------- Boss
  static const double bossPhase2Threshold = 0.70; // plan section 11
  static const double bossPhase3Threshold = 0.30;
  static const double bossActivationRange = 420;

  // ------------------------------------------------------------------ Souls
  static const double soulsLossOnDeathFactor = 0.5; // souls-like penalty
}
