class GameConfig {
  GameConfig._();

  // ---------------------------------------------------------------- Physics
  static const double gravity = 1500;
  static const double maxFallSpeed = 900;

  // ----------------------------------------------------------------- Player
  static const double walkSpeed = 160;
  static const double runSpeed = 260;
  static const double jumpVelocity = -560;
  static const double coyoteTime = 0.10;

  static const double playerMaxHp = 100;
  static const double playerMaxMana = 60;
  static const double playerMaxStamina = 100;
  static const double playerAttack = 20;
  static const double playerDefense = 5;

  // ------------------------------------------------------------------- Dash
  static const double dashSpeed = 540;
  static const double dashDuration = 0.18;
  static const double dashCooldown = 0.85;
  static const double dashStaminaCost = 20;

  // ----------------------------------------------------------------- Combat
  static const double attackDuration = 0.32;
  static const double attackHitStart = 0.08;
  static const double attackHitEnd = 0.22;
  static const double attackStaminaCost = 10;
  static const double comboResetTime = 0.9;
  static const int maxCombo = 3;
  static const List<double> comboMultipliers = [1.0, 1.15, 1.5];
  static const double meleeRangeX = 54;
  static const double meleeRangeY = 46;

  static const double critChance = 0.06;
  static const double critMultiplier = 2.0;

  static const double blockDamageReduction = 0.7;
  static const double blockStaminaFactor = 0.8;

  static const double hurtInvincibleTime = 0.6;
  static const double knockbackX = 180;
  static const double knockbackY = -150;

  // -------------------------------------------------------------- Resources
  static const double staminaRegen = 26;
  static const double manaRegen = 5;

  // ------------------------------------------------------------------ Skill
  static const double skillManaCost = 25;
  static const double skillMultiplier = 1.5;
  static const double skillCooldown = 3.0;
  static const double skillProjectileSpeed = 450;

  // ------------------------------------------------------------------ Items
  static const double potionHeal = 45;

  // --------------------------------------------------------------------- AI
  static const double defaultDetectRange = 160;
  static const double defaultAttackRange = 42;

  // ------------------------------------------------------------------- Boss
  static const double bossPhase2Threshold = 0.70;
  static const double bossPhase3Threshold = 0.30;
  static const double bossActivationRange = 400;

  // ------------------------------------------------------------------ Souls
  static const double soulsLossOnDeathFactor = 0.5;
}
