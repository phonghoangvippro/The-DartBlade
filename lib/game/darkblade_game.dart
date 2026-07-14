import 'dart:async';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../boss/boss.dart';
import '../combat/damage.dart';
import '../core/constants/game_constants.dart';
import '../core/logger/game_logger.dart';
import '../core/services/audio_service.dart';
import '../inventory/inventory.dart';
import '../inventory/item.dart';
import '../player/player.dart';
import '../save/save_model.dart';
import '../save/save_service.dart';
import '../world/damage_number.dart';
import '../world/level.dart';
import '../world/level_data.dart';
import 'game_camera.dart';

enum GamePhase { menu, playing, paused, gameOver, victory }

/// Root game class: owns the world, camera, player, level flow and
/// exposes hooks used by UI overlays (plan sections 5 & 7).
class DarkbladeGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  DarkbladeGame({required this.saveService});

  final SaveService saveService;
  final Inventory inventory = Inventory();

  late Player player;

  /// True once [player] has been created by the first level load; guards
  /// UI widgets that may build while we are still in the main menu.
  bool playerReady = false;

  late GameCameraController cameraController;
  Level? currentLevel;
  int currentLevelIndex = 0;
  final Set<int> defeatedBosses = {};

  GamePhase phase = GamePhase.menu;

  /// On-screen touch controls (auto-enabled on Android/iOS, can be toggled
  /// in Settings so tablets with keyboards or desktops can override it).
  bool touchControlsEnabled = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Notifies the HUD about the active boss (health bar).
  final ValueNotifier<Boss?> activeBoss = ValueNotifier(null);

  /// Simple toast queue consumed by the HUD.
  final ValueNotifier<String?> toast = ValueNotifier(null);
  Timer? _toastTimer;

  World get gameWorld => world;

  @override
  Color backgroundColor() =>
      currentLevel?.definition.backgroundColor ??
      const Color(0xFF101018);

  @override
  Future<void> onLoad() async {
    // The camera setter adds the component to the tree automatically.
    camera = CameraComponent.withFixedResolution(
      world: world,
      width: GameConstants.viewWidth,
      height: GameConstants.viewHeight,
    );
    cameraController = GameCameraController(camera);

    // Start paused behind the main menu overlay.
    pauseEngine();
    overlays.add(OverlayIds.mainMenu);
  }

  // -------------------------------------------------------------- game flow
  Future<void> startNewGame() async {
    await saveService.deleteSave();
    inventory.clear();
    inventory.addItem(Item.healthPotion, 3);
    defeatedBosses.clear();
    await _loadLevel(0);
    _beginPlay();
  }

  Future<void> continueGame() async {
    final save = saveService.load();
    if (save == null) {
      await startNewGame();
      return;
    }
    defeatedBosses
      ..clear()
      ..addAll(save.defeatedBosses);
    await _loadLevel(save.currentLevel);
    player.position = Vector2(save.playerX, save.playerY);
    player.respawnPoint = player.position.clone();
    player.health.current = save.hp.clamp(1, player.health.max);
    player.stats
      ..mana = save.mana
      ..stamina = save.stamina
      ..souls = save.souls;
    inventory.restoreFromJson(save.inventoryJson);
    _applyEquipmentBonuses();
    _beginPlay();
  }

  void _beginPlay() {
    phase = GamePhase.playing;
    overlays.remove(OverlayIds.mainMenu);
    overlays.remove(OverlayIds.gameOver);
    overlays.remove(OverlayIds.victory);
    resumeEngine();
    AudioService.instance.playMusic('theme.mp3');
  }

  Future<void> _loadLevel(int index) async {
    // Tear down the previous level.
    world.removeAll(world.children.toList());
    activeBoss.value = null;

    currentLevelIndex = index.clamp(0, Levels.all.length - 1);
    final def = Levels.all[currentLevelIndex];

    final level = Level(def);
    currentLevel = level;
    await world.add(level);

    player = Player(position: def.playerSpawnV);
    player.platformsProvider = () => level.platforms;
    _applyEquipmentBonuses();
    await world.add(player);
    playerReady = true;

    // Unlock the portal if this level's boss was already defeated.
    if (defeatedBosses.contains(currentLevelIndex)) {
      level.boss?.removeFromParent();
      level.boss = null;
      level.portal?.unlocked = true;
    }

    cameraController
      ..worldSize = Vector2(def.worldSize.width, def.worldSize.height)
      ..follow(player);

    showToast(def.name);
    GameLogger.info('Level', 'Loaded map ${def.id}: ${def.name}');
  }

  Future<void> goToNextLevel() async {
    saveProgress();
    if (currentLevelIndex >= Levels.all.length - 1) {
      _showVictory();
      return;
    }
    await _loadLevel(currentLevelIndex + 1);
    saveProgress();
  }

  // ------------------------------------------------------------------ hooks
  void onPlayerDied() {
    phase = GamePhase.gameOver;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (phase == GamePhase.gameOver) {
        overlays.add(OverlayIds.gameOver);
        pauseEngine();
      }
    });
  }

  void respawnPlayer() {
    overlays.remove(OverlayIds.gameOver);
    phase = GamePhase.playing;
    player.respawn();
    activeBoss.value?.let((boss) {
      // Reset an engaged boss when the player respawns.
      if (!boss.isRemoved && !boss.isDead) {
        boss.health.refill();
      }
    });
    activeBoss.value = null;
    resumeEngine();
  }

  void onPlayerDamaged(double amount) {
    shakeCamera(intensity: 3, duration: 0.2);
  }

  void onPlayerDealtDamage(DamageResult result) {
    if (result.isCritical) {
      shakeCamera(intensity: 4, duration: 0.15);
    }
  }

  void onBossActivated(Boss boss) {
    activeBoss.value = boss;
    shakeCamera(intensity: 6, duration: 0.8);
  }

  void onBossDefeated(Boss boss) {
    activeBoss.value = null;
    defeatedBosses.add(currentLevelIndex);
    currentLevel?.portal?.unlocked = true;
    shakeCamera(intensity: 10, duration: 0.8);
    showToast('${boss.archetype.name} has fallen');
    saveProgress();
    if (boss.isFinalBoss) {
      Future.delayed(const Duration(seconds: 2), _showVictory);
    }
  }

  void _showVictory() {
    if (phase == GamePhase.victory) return;
    phase = GamePhase.victory;
    overlays.add(OverlayIds.victory);
    pauseEngine();
  }

  // -------------------------------------------------------------- inventory
  void useEquippedPotion() {
    final heal = inventory.usePotion();
    if (heal == null) {
      showToast('No potions left!');
      return;
    }
    player.health.heal(heal);
    showToast('+${heal.toStringAsFixed(0)} HP');
    AudioService.instance.playSfx('potion.wav');
  }

  void _applyEquipmentBonuses() {
    player.stats
      ..equipmentAttackBonus = inventory.attackBonus
      ..equipmentDefenseBonus = inventory.defenseBonus;
  }

  /// Called by the inventory overlay after equip changes.
  void refreshEquipment() => _applyEquipmentBonuses();

  // ------------------------------------------------------------------- save
  void saveProgress() {
    saveService.save(SaveModel(
      currentLevel: currentLevelIndex,
      playerX: player.respawnPoint.x,
      playerY: player.respawnPoint.y,
      hp: player.health.current,
      mana: player.stats.mana,
      stamina: player.stats.stamina,
      souls: player.stats.souls,
      inventoryJson: inventory.toJson(),
      defeatedBosses: defeatedBosses.toList(),
    ));
  }

  // --------------------------------------------------------------- niceties
  void shakeCamera({double intensity = 6, double duration = 0.4}) {
    cameraController.shake(intensity: intensity, duration: duration);
  }

  void spawnDamageNumber(Vector2 position, double amount, bool critical) {
    world.add(DamageNumber(
      position: position,
      amount: amount,
      critical: critical,
    ));
  }

  void showToast(String message) {
    toast.value = message;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      toast.value = null;
    });
  }

  void togglePause() {
    if (phase == GamePhase.playing) {
      phase = GamePhase.paused;
      overlays.add(OverlayIds.pauseMenu);
      pauseEngine();
    } else if (phase == GamePhase.paused) {
      phase = GamePhase.playing;
      overlays.remove(OverlayIds.pauseMenu);
      overlays.remove(OverlayIds.settingsMenu);
      overlays.remove(OverlayIds.inventory);
      resumeEngine();
    }
  }

  void openInventory() {
    if (phase != GamePhase.playing) return;
    phase = GamePhase.paused;
    overlays.add(OverlayIds.inventory);
    pauseEngine();
  }

  // ------------------------------------------------------------------ input
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (overlays.isActive(OverlayIds.inventory)) {
          togglePause(); // closes inventory & resumes
        } else if (phase == GamePhase.playing ||
            phase == GamePhase.paused) {
          togglePause();
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE &&
          phase == GamePhase.playing) {
        openInventory();
        return KeyEventResult.handled;
      }
    }

    if (phase == GamePhase.playing) {
      player.controller.readKeyboard(keysPressed);
    }
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (phase == GamePhase.playing || phase == GamePhase.gameOver) {
      cameraController.update(dt);
    }
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T it) block) => block(this);
}
