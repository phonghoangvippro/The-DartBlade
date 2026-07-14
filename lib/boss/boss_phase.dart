/// Boss phases (plan section 11):
///   Phase 1: 100%..70%  - normal attacks
///   Phase 2:  70%..30%  - adds special skill (projectiles)
///   Phase 3:  30%..0%   - ultimate + rage (faster, stronger)
enum BossPhase { phase1, phase2, phase3 }

/// Behavior states of the boss.
enum BossState { dormant, intro, idle, walk, attack, skill, ultimate, dead }

class BossPhaseConfig {
  const BossPhaseConfig({
    required this.moveSpeed,
    required this.attackCooldown,
    required this.damageMultiplier,
    this.usesSkill = false,
    this.usesUltimate = false,
  });

  final double moveSpeed;
  final double attackCooldown;
  final double damageMultiplier;
  final bool usesSkill;
  final bool usesUltimate;

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
      moveSpeed: 125,
      attackCooldown: 0.85,
      damageMultiplier: 1.5,
      usesSkill: true,
      usesUltimate: true,
    ),
  };
}
