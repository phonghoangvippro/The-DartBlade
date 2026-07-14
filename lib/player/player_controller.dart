import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Translates raw input (keyboard AND on-screen touch controls) into
/// per-frame intents for the player.
///
/// Keyboard layout (desktop):
///   A / D or Arrow keys ... move
///   Space / W / Up ........ jump
///   J ..................... attack
///   K / Shift ............. dash
///   L ..................... block (hold)
///   I ..................... skill (Blade Wave)
///   Q ..................... potion
///
/// Touch layout (mobile): virtual D-pad + action buttons feed the same
/// intents through the `touch*` fields below, so gameplay code does not
/// care where the input came from.
class PlayerController {
  // ------------------------------------------------------- resolved intents
  double moveDirection = 0; // -1 .. 1
  bool jumpPressed = false;
  bool attackPressed = false;
  bool dashPressed = false;
  bool blockHeld = false;
  bool skillPressed = false;
  bool potionPressed = false;

  // ------------------------------------------------------------ touch state
  /// Continuous states pushed by the on-screen controls.
  double touchMoveDirection = 0;
  bool touchJumpHeld = false;
  bool touchAttackHeld = false;
  bool touchDashHeld = false;
  bool touchBlockHeld = false;
  bool touchSkillHeld = false;
  bool touchPotionHeld = false;

  // --------------------------------------------------------- keyboard state
  double _keyMoveDirection = 0;
  bool _keyJumpHeld = false;
  bool _keyAttackHeld = false;
  bool _keyDashHeld = false;
  bool _keyBlockHeld = false;
  bool _keySkillHeld = false;
  bool _keyPotionHeld = false;

  // Edge detection (shared between both sources).
  bool _jumpWasDown = false;
  bool _attackWasDown = false;
  bool _dashWasDown = false;
  bool _skillWasDown = false;
  bool _potionWasDown = false;

  void readKeyboard(Set<LogicalKeyboardKey> keys) {
    _keyMoveDirection = 0;
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) {
      _keyMoveDirection -= 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) {
      _keyMoveDirection += 1;
    }

    _keyJumpHeld = keys.contains(LogicalKeyboardKey.space) ||
        keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp);
    _keyAttackHeld = keys.contains(LogicalKeyboardKey.keyJ);
    _keyDashHeld = keys.contains(LogicalKeyboardKey.keyK) ||
        keys.contains(LogicalKeyboardKey.shiftLeft);
    _keyBlockHeld = keys.contains(LogicalKeyboardKey.keyL);
    _keySkillHeld = keys.contains(LogicalKeyboardKey.keyI);
    _keyPotionHeld = keys.contains(LogicalKeyboardKey.keyQ);
  }

  /// Merges keyboard + touch into the final intents.
  /// Call once per frame BEFORE the player consumes input.
  void resolveFrame() {
    moveDirection = touchMoveDirection != 0
        ? touchMoveDirection.clamp(-1, 1)
        : _keyMoveDirection;

    final jumpDown = _keyJumpHeld || touchJumpHeld;
    jumpPressed = jumpDown && !_jumpWasDown;
    _jumpWasDown = jumpDown;

    final attackDown = _keyAttackHeld || touchAttackHeld;
    attackPressed = attackDown && !_attackWasDown;
    _attackWasDown = attackDown;

    final dashDown = _keyDashHeld || touchDashHeld;
    dashPressed = dashDown && !_dashWasDown;
    _dashWasDown = dashDown;

    blockHeld = _keyBlockHeld || touchBlockHeld;

    final skillDown = _keySkillHeld || touchSkillHeld;
    skillPressed = skillDown && !_skillWasDown;
    _skillWasDown = skillDown;

    final potionDown = _keyPotionHeld || touchPotionHeld;
    potionPressed = potionDown && !_potionWasDown;
    _potionWasDown = potionDown;
  }

  /// Consume one-shot intents at end of frame.
  void clearOneShots() {
    jumpPressed = false;
    attackPressed = false;
    dashPressed = false;
    skillPressed = false;
    potionPressed = false;
  }

  Vector2 get aim => Vector2(moveDirection, 0);
}
