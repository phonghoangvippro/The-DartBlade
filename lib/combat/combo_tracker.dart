import '../core/config/game_config.dart';

/// Tracks the player's 3-hit combo chain (FR-004, FR-014).
///
/// Attack1 -> Attack2 -> Attack3; if the player waits longer than
/// [GameConfig.comboResetTime] between swings the chain resets.
class ComboTracker {
  ComboTracker({
    this.maxCombo = GameConfig.maxCombo,
    this.resetTime = GameConfig.comboResetTime,
  });

  final int maxCombo;
  final double resetTime;

  int _step = 0;
  double _timer = 0;

  /// Current step in the chain: 0 = not attacking yet, 1..maxCombo.
  int get step => _step;

  /// Damage multiplier for the current step.
  double get multiplier =>
      _step == 0 ? 1.0 : GameConfig.comboMultipliers[_step - 1];

  /// Registers a new attack; returns the combo step used (1-based).
  int registerAttack() {
    if (_step >= maxCombo) {
      _step = 1;
    } else {
      _step += 1;
    }
    _timer = 0;
    return _step;
  }

  void update(double dt) {
    if (_step == 0) return;
    _timer += dt;
    if (_timer >= resetTime) reset();
  }

  void reset() {
    _step = 0;
    _timer = 0;
  }
}
