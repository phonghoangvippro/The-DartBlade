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
import '../world/npc.dart';
import '../weapon/blade_wave.dart';
import 'game_camera.dart';

enum GamePhase { menu, playing, paused, gameOver, victory, cutscene, dialogue }

class DarkbladeGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  DarkbladeGame({required this.saveService});

  static const double _resumeSpikeDt = 0.25;
  static const double _resumeRecoveryDt = 1 / 60;

  final SaveService saveService;
  final Inventory inventory = Inventory();

  late Player player;

  bool playerReady = false;

  late GameCameraController cameraController;
  Level? currentLevel;
  int currentLevelIndex = 0;
  final Set<int> defeatedBosses = {};
  final Set<String> defeatedEnemies = {};

  GamePhase phase = GamePhase.menu;

  bool touchControlsEnabled =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  final ValueNotifier<Boss?> activeBoss = ValueNotifier(null);
  final ValueNotifier<String?> toast = ValueNotifier(null);
  Timer? _toastTimer;
  Timer? _saveTimer;
  final ValueNotifier<bool> canInteract = ValueNotifier(false);
  Npc? _nearbyNpc;
  double _nearbyNpcDistance = double.infinity;
  double fps = 0;
  double _fpsElapsed = 0;
  int _fpsFrames = 0;
  bool lowFpsMode = false;
  int _qualityRecoverySamples = 0;
  static const int _maxPooledBladeWaves = 32;
  final List<BladeWave> _bladeWavePool = [];

  World get gameWorld => world;

  @override
  Color backgroundColor() =>
      currentLevel?.definition.backgroundColor ?? const Color(0xFF0A0612);

  @override
  Future<void> onLoad() async {
    camera = CameraComponent(world: world);
    cameraController = GameCameraController(camera);

    await AudioService.instance.preload();

    pauseEngine();
    overlays.add(OverlayIds.mainMenu);
    AudioService.instance.playMusic('theme.wav');
  }

  void spawnBladeWave({
    required Vector2 position,
    required int direction,
    required double damage,
    String faction = 'player',
    double maxDistance = 380,
    Color color = const Color(0xFF7B2FF2),
    double velocityY = 0,
  }) {
    final wave =
        _bladeWavePool.isEmpty
              ? BladeWave(
                  position: position,
                  direction: direction,
                  damage: damage,
                  faction: faction,
                  maxDistance: maxDistance,
                  color: color,
                  velocityY: velocityY,
                )
              : _bladeWavePool.removeLast()
          ..reset(
            position: position,
            direction: direction,
            damage: damage,
            faction: faction,
            maxDistance: maxDistance,
            color: color,
            velocityY: velocityY,
          );
    gameWorld.add(wave);
  }

  void recycleBladeWave(BladeWave wave) {
    if (_bladeWavePool.length < _maxPooledBladeWaves &&
        !_bladeWavePool.contains(wave)) {
      _bladeWavePool.add(wave);
    }
  }

  // -------------------------------------------------------------- game flow
  Future<void> startNewGame() async {
    await saveService.deleteSave();
    inventory.clear();
    inventory.addItem(Item.healthPotion, 3);
    defeatedBosses.clear();
    defeatedEnemies.clear();
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
    defeatedEnemies
      ..clear()
      ..addAll(save.defeatedEnemies);
    await _loadLevel(save.currentLevel);
    player.unlockDash = true;
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
    phase = GamePhase.cutscene;
    overlays.remove(OverlayIds.mainMenu);
    resumeEngine();
    final cutscene = IntroCutscene(
      scenes: Levels.all[currentLevelIndex].cinematic,
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
    playerReady = false;
    final oldWorldChildren = world.children.toList(growable: false);
    final oldCutscenes = camera.viewport.children
        .whereType<IntroCutscene>()
        .toList(growable: false);
    world.removeAll(oldWorldChildren);
    camera.viewport.removeAll(oldCutscenes);

    // Flame schedules removals for the next lifecycle pass. Wait until the
    // old level has disposed its cached background and all old hitboxes have
    // left collision detection before mounting the next level.
    if (oldWorldChildren.isNotEmpty || oldCutscenes.isNotEmpty) {
      if (paused) resumeEngine();
      await lifecycleEventsProcessed;
    }
    activeBoss.value = null;
    _nearbyNpc = null;
    _nearbyNpcDistance = double.infinity;
    canInteract.value = false;

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
    _playIntro();
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
    final boss = activeBoss.value;
    if (boss != null && !boss.isRemoved && !boss.isDead) {
      boss.health.refill();
    } else {
      activeBoss.value = null;
    }
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
    final lore = switch (boss.archetype.behavior) {
      BossBehavior.knight => const DialogueLine(
        speaker: 'SIR ALDRIC',
        text: 'Thanh kiếm này... vì sao lại run lên khi ngươi đến gần?',
        color: Color(0xFFE0C9FF),
      ),
      BossBehavior.treant => const DialogueLine(
        speaker: 'ELDER TREANT',
        text:
            'Mỗi chiếc lá là một ký ức. Mỗi nhát chém của ngươi sẽ khiến một người chết thêm lần nữa.',
        color: Color(0xFF77FF99),
      ),
      BossBehavior.queen => const DialogueLine(
        speaker: 'PRINCESS ELENIA',
        text:
            'Ta từng yêu hoa, âm nhạc và ánh sáng. Giờ ta chỉ còn nhớ... mỗi đêm cha đều khóc.',
        color: Color(0xFFFF7799),
      ),
      BossBehavior.varkhan => const DialogueLine(
        speaker: 'KING VARKHAN',
        text:
            'Ta đã cứu con bé khỏi ánh sáng của các ngươi. Đừng gọi tình yêu của ta là tội lỗi.',
        color: Color(0xFFFF5544),
      ),
    };
    showDialogue([lore]);
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

  void onEnemyDefeated(String saveId) {
    defeatedEnemies.add(saveId);
    scheduleSaveProgress();
  }

  void _showVictory() {
    if (phase == GamePhase.victory) return;
    phase = GamePhase.victory;
    overlays.add(OverlayIds.victory);
    pauseEngine();
  }

  // -------------------------------------------------------------- inventory
  int get potionCount => inventory.countOf(Item.healthPotion.id);

  bool get canUsePotion =>
      playerReady && !player.health.isFull && potionCount > 0;

  void useEquippedPotion() {
    if (player.health.isFull) {
      showToast('HP is already full');
      return;
    }
    final heal = inventory.usePotion();
    if (heal == null) {
      showToast('No potions left!');
      return;
    }
    final before = player.health.current;
    player.health.heal(heal);
    final restored = player.health.current - before;
    showToast('+${restored.toStringAsFixed(0)} HP');
    AudioService.instance.playSfx('potion.wav');
  }

  void _applyEquipmentBonuses() {
    player.stats
      ..equipmentAttackBonus = inventory.attackBonus
      ..equipmentDefenseBonus = inventory.defenseBonus;
  }

  void refreshEquipment() => _applyEquipmentBonuses();

  // ------------------------------------------------------------------- save
  Future<void> saveProgress() {
    _saveTimer?.cancel();
    return saveService.save(
      SaveModel(
        currentLevel: currentLevelIndex,
        playerX: player.position.x,
        playerY: player.position.y,
        hp: player.health.current,
        mana: player.stats.mana,
        stamina: player.stats.stamina,
        souls: player.stats.souls,
        inventoryJson: inventory.toJson(),
        defeatedBosses: defeatedBosses.toList(),
        defeatedEnemies: defeatedEnemies.toList(),
        unlockDash: player.unlockDash,
      ),
    );
  }

  void scheduleSaveProgress() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), () {
      saveProgress();
    });
  }

  // --------------------------------------------------------------- niceties
  void shakeCamera({double intensity = 6, double duration = 0.4}) {
    cameraController.shake(intensity: intensity, duration: duration);
  }

  void spawnDamageNumber(Vector2 position, double amount, bool critical) {
    if (lowFpsMode && !critical) return;
    if (world.children.query<DamageNumber>().length > 18) return;
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

  void offerInteraction(Npc npc, double distance) {
    if (_nearbyNpc == null ||
        _nearbyNpc == npc ||
        distance < _nearbyNpcDistance) {
      _nearbyNpc = npc;
      _nearbyNpcDistance = distance;
      canInteract.value = true;
    }
  }

  void clearInteraction(Npc npc) {
    if (_nearbyNpc != npc) return;
    _nearbyNpc = null;
    _nearbyNpcDistance = double.infinity;
    canInteract.value = false;
  }

  void interactWithNpc() {
    if (phase != GamePhase.playing) return;
    _nearbyNpc?.interact();
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
      if (event.logicalKey == LogicalKeyboardKey.keyF &&
          phase == GamePhase.playing &&
          canInteract.value) {
        interactWithNpc();
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
    final simDt = dt > _resumeSpikeDt ? _resumeRecoveryDt : dt;
    super.update(simDt);
    if (phase == GamePhase.playing || phase == GamePhase.gameOver) {
      cameraController.update(simDt);
    }
    if (phase == GamePhase.playing && simDt > 0) {
      _fpsElapsed += simDt;
      _fpsFrames++;
      if (_fpsElapsed >= 0.5) {
        fps = _fpsFrames / _fpsElapsed;
        if (fps < 40) {
          lowFpsMode = true;
          _qualityRecoverySamples = 0;
        } else if (lowFpsMode && fps > 52) {
          _qualityRecoverySamples++;
          if (_qualityRecoverySamples >= 10) {
            lowFpsMode = false;
            _qualityRecoverySamples = 0;
          }
        } else if (fps <= 52) {
          _qualityRecoverySamples = 0;
        }
        _fpsElapsed = 0;
        _fpsFrames = 0;
      }
    }
  }
}
