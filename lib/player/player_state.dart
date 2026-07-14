/// All player animation / logic states (FR-009).
enum PlayerState {
  idle,
  run,
  jump,
  fall,
  attack1,
  attack2,
  attack3,
  dash,
  block,
  hurt,
  dead,
}

extension PlayerStateX on PlayerState {
  bool get isAttacking =>
      this == PlayerState.attack1 ||
      this == PlayerState.attack2 ||
      this == PlayerState.attack3;

  /// States during which movement input is ignored.
  bool get locksMovement =>
      isAttacking ||
      this == PlayerState.dash ||
      this == PlayerState.hurt ||
      this == PlayerState.dead;
}
