enum BossPhase { phase1, phase2, phase3 }

enum BossState {
  dormant,
  intro,
  idle,
  walk,
  attack,
  skill,
  ultimate,
  dead,
  summon,
  teleport,
  fly,
}

class BossPhaseConfig {
  const BossPhaseConfig({
    required this.moveSpeed,
    required this.attackCooldown,
    required this.damageMultiplier,
    this.usesSkill = false,
    this.usesUltimate = false,
    this.usesSummon = false,
    this.usesTeleport = false,
    this.usesFlight = false,
  });

  final double moveSpeed;
  final double attackCooldown;
  final double damageMultiplier;
  final bool usesSkill;
  final bool usesUltimate;
  final bool usesSummon;
  final bool usesTeleport;
  final bool usesFlight;

  static const configs = <BossPhase, BossPhaseConfig>{
    BossPhase.phase1: BossPhaseConfig(
      moveSpeed: 70,
      attackCooldown: 1.6,
      damageMultiplier: 1.0,
    ),
    BossPhase.phase2: BossPhaseConfig(
      moveSpeed: 95,
      attackCooldown: 1.2,
      damageMultiplier: 1.2,
      usesSkill: true,
    ),
    BossPhase.phase3: BossPhaseConfig(
      moveSpeed: 130,
      attackCooldown: 0.8,
      damageMultiplier: 1.5,
      usesSkill: true,
      usesUltimate: true,
      usesSummon: true,
    ),
  };
}
