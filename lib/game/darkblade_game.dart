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
import '../story/dialogue.dart';
import '../world/damage_number.dart';
import '../world/level.dart';
import '../world/level_data.dart';
import 'game_camera.dart';

enum GamePhase { menu, playing, paused, gameOver, victory, cutscene, dialogue }

class DarkbladeGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  DarkbladeGame({required this.saveService});

  final SaveService saveService;
  final Inventory inventory = Inventory();

  late Player player;

  bool playerReady = false;

  late GameCameraController cameraController;
  Level? currentLevel;
  int currentLevelIndex = 0;
  final Set<int> defeatedBosses = {};

  GamePhase phase = GamePhase.menu;

  bool touchControlsEnabled =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  final ValueNotifier<Boss?> activeBoss = ValueNotifier(null);
  final ValueNotifier<String?> toast = ValueNotifier(null);
  Timer? _toastTimer;

  bool _introPlayed = false;

  World get gameWorld => world;

  @override
  Color backgroundColor() =>
      currentLevel?.definition.backgroundColor ?? const Color(0xFF0A0612);

  @override
  Future<void> onLoad() async {
    camera = CameraComponent(world: world);
    cameraController = GameCameraController(camera);

    pauseEngine();
    overlays.add(OverlayIds.mainMenu);
    AudioService.instance.playMusic('theme.wav');
  }

  // -------------------------------------------------------------- game flow
  Future<void> startNewGame() async {
    await saveService.deleteSave();
    inventory.clear();
    inventory.addItem(Item.healthPotion, 3);
    defeatedBosses.clear();
    _introPlayed = false;
    await _loadLevel(0);
    _playIntro();
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
    player.unlockDash = save.unlockDash;
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

  void _playIntro() {
    if (_introPlayed) {
      _beginPlay();
      return;
    }
    _introPlayed = true;
    phase = GamePhase.cutscene;
    overlays.remove(OverlayIds.mainMenu);
    resumeEngine();
    final cutscene = IntroCutscene(
      onComplete: () {
        _showChapterTitle();
      },
    );
    camera.viewport.add(cutscene);
  }

  void _showChapterTitle() {
    phase = GamePhase.cutscene;
    final def = Levels.all[currentLevelIndex];
    showToast(def.chapterTitle);
    Future.delayed(const Duration(seconds: 2), () {
      _beginPlay();
    });
  }

  String _themeForLevel(int index) {
    const themes = [
      'village_theme.wav',
      'forest_theme.wav',
      'castle_theme.wav',
      'abyss_theme.wav',
    ];
    return themes[index.clamp(0, themes.length - 1)];
  }

  void _beginPlay() {
    phase = GamePhase.playing;
    overlays.remove(OverlayIds.mainMenu);
    overlays.remove(OverlayIds.gameOver);
    overlays.remove(OverlayIds.victory);
    resumeEngine();
    AudioService.instance.playMusic(_themeForLevel(currentLevelIndex));
  }

  Future<void> _loadLevel(int index) async {
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
    _showChapterTitle();
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
    AudioService.instance.playMusic('boss_theme.wav');
  }

  void onBossDefeated(Boss boss) {
    activeBoss.value = null;
    defeatedBosses.add(currentLevelIndex);
    currentLevel?.portal?.unlocked = true;
    shakeCamera(intensity: 10, duration: 0.8);
    showToast('${boss.archetype.name} has fallen');
    AudioService.instance.playMusic(_themeForLevel(currentLevelIndex));
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

  void refreshEquipment() => _applyEquipmentBonuses();

  // ------------------------------------------------------------------- save
  void saveProgress() {
    saveService.save(
      SaveModel(
        currentLevel: currentLevelIndex,
        playerX: player.respawnPoint.x,
        playerY: player.respawnPoint.y,
        hp: player.health.current,
        mana: player.stats.mana,
        stamina: player.stats.stamina,
        souls: player.stats.souls,
        inventoryJson: inventory.toJson(),
        defeatedBosses: defeatedBosses.toList(),
        unlockDash: player.unlockDash,
      ),
    );
  }

  // --------------------------------------------------------------- niceties
  void shakeCamera({double intensity = 6, double duration = 0.4}) {
    cameraController.shake(intensity: intensity, duration: duration);
  }

  void spawnDamageNumber(Vector2 position, double amount, bool critical) {
    world.add(
      DamageNumber(position: position, amount: amount, critical: critical),
    );
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

  // ----------------------------------------------------------- story hooks
  void showDialogue(List<DialogueLine> lines, {VoidCallback? onComplete}) {
    if (lines.isEmpty) {
      onComplete?.call();
      return;
    }
    phase = GamePhase.dialogue;
    final seq = DialogueSequence(
      lines: lines,
      onComplete: () {
        phase = GamePhase.playing;
        resumeEngine();
        onComplete?.call();
      },
    );
    camera.viewport.add(seq);
  }

  // ------------------------------------------------------------------ input
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        // Advance cutscene or dialogue
        if (phase == GamePhase.cutscene) {
          _advanceCutscene();
          return KeyEventResult.handled;
        }
        if (phase == GamePhase.dialogue) {
          _advanceDialogue();
          return KeyEventResult.handled;
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (overlays.isActive(OverlayIds.inventory)) {
          togglePause();
        } else if (phase == GamePhase.playing || phase == GamePhase.paused) {
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

  void _advanceCutscene() {
    final cutscene = camera.viewport.children
        .query<IntroCutscene>()
        .firstOrNull;
    cutscene?.advance();
  }

  void _advanceDialogue() {
    final dialogue = camera.viewport.children
        .query<DialogueSequence>()
        .firstOrNull;
    dialogue?.advance();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (phase == GamePhase.cutscene) {
      _advanceCutscene();
      event.handled = true;
    } else if (phase == GamePhase.dialogue) {
      _advanceDialogue();
      event.handled = true;
    }
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
