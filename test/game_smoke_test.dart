import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/core/constants/game_constants.dart';
import 'package:the_darkblade/enemy/enemy.dart';
import 'package:the_darkblade/game/darkblade_game.dart';
import 'package:the_darkblade/player/player_state.dart';
import 'package:the_darkblade/save/save_service.dart';
import 'package:the_darkblade/world/level_data.dart';
import 'package:the_darkblade/world/level.dart';
import 'package:the_darkblade/world/npc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget stub(BuildContext context, DarkbladeGame game) =>
      const SizedBox.shrink();

  Future<DarkbladeGame> bootGame(WidgetTester tester) async {
    final game = DarkbladeGame(saveService: SaveService());
    await tester.pumpWidget(
      GameWidget<DarkbladeGame>(
        game: game,
        overlayBuilderMap: {
          OverlayIds.mainMenu: stub,
          OverlayIds.pauseMenu: stub,
          OverlayIds.settingsMenu: stub,
          OverlayIds.gameOver: stub,
          OverlayIds.victory: stub,
          OverlayIds.inventory: stub,
        },
      ),
    );
    await tester.pump();
    await game.startNewGame();
    await tester.pump();
    game.update(0);
    return game;
  }

  Future<void> flushTimers(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 3));

  testWidgets('game boots and loads the first level', (tester) async {
    final game = await bootGame(tester);

    expect(game.phase, GamePhase.cutscene);
    expect(game.currentLevelIndex, 0);
    expect(game.currentLevel!.definition.name, 'Village of Ashes');
    expect(game.currentLevel!.platforms, isNotEmpty);

    await flushTimers(tester);
  });

  testWidgets('player falls onto the ground and idles', (tester) async {
    final game = await bootGame(tester);

    for (var i = 0; i < 60; i++) {
      game.update(1 / 60);
    }

    // During cutscene, player may not be on ground yet
    expect(game.player.isDead, isFalse);

    await flushTimers(tester);
  });

  testWidgets('enemies spawn and run their AI without errors', (tester) async {
    final game = await bootGame(tester);

    final enemies = game.currentLevel!.children.whereType<Enemy>().toList();
    expect(enemies.length, Levels.villageOfAshes.enemies.length);

    game.phase = GamePhase.playing;
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    expect(game.phase, GamePhase.playing);

    await flushTimers(tester);
  });

  testWidgets('dash is available from a new game', (tester) async {
    final game = await bootGame(tester);
    game.phase = GamePhase.playing;
    game.player.controller.touchDashHeld = true;

    game.update(1 / 60);

    expect(game.player.unlockDash, isTrue);
    expect(game.player.state, PlayerState.dash);
    expect(game.player.stats.stamina, lessThan(100));
    await flushTimers(tester);
  });

  testWidgets('potions heal repeatedly and are not consumed at full HP', (
    tester,
  ) async {
    final game = await bootGame(tester);
    expect(game.potionCount, 3);

    game.useEquippedPotion();
    expect(game.potionCount, 3);

    game.player.health.current = 10;
    game.useEquippedPotion();
    expect(game.player.health.current, 55);
    expect(game.potionCount, 2);

    game.useEquippedPotion();
    expect(game.player.health.current, 100);
    expect(game.potionCount, 1);
    await flushTimers(tester);
  });

  testWidgets('all four levels load without errors', (tester) async {
    final game = await bootGame(tester);

    for (var i = 0; i < Levels.all.length; i++) {
      if (i > 0) {
        final transition = game.goToNextLevel();
        await tester.pump();
        await transition;
      }
      await tester.pump();
      for (var f = 0; f < 30; f++) {
        game.update(1 / 60);
      }
      expect(game.currentLevelIndex, i);
      expect(game.currentLevel!.definition.id, i);
      expect(game.currentLevel!.definition.cinematic, isNotEmpty);
      expect(game.currentLevel!.children.whereType<Npc>(), isNotEmpty);
      expect(
        game.world.children.whereType<Level>(),
        hasLength(1),
        reason: 'A previous level must be fully removed before loading $i',
      );
    }

    await flushTimers(tester);
  });

  testWidgets('boss health bar remains active after checkpoint respawn', (
    tester,
  ) async {
    final game = await bootGame(tester);
    final boss = game.currentLevel!.boss!;
    game.onBossActivated(boss);
    boss.health.damage(100);

    game.respawnPlayer();

    expect(game.activeBoss.value, same(boss));
    expect(boss.health.current, boss.health.max);

    await flushTimers(tester);
  });

  test('chapter 2 has no solid wall blocking the final approach', () {
    final finalApproach = Levels.forestOfWhispers.platforms.where(
      (platform) => !platform.oneWay && platform.x >= 2400 && platform.x < 2950,
    );

    expect(finalApproach, isEmpty);
  });

  test('chapter 3 opening wall is low enough to jump over', () {
    final openingRoute = Levels.crimsonCastle.platforms.where(
      (platform) => !platform.oneWay && platform.x > 0 && platform.x < 1000,
    );

    expect(openingRoute, hasLength(1));
    expect(openingRoute.single.h, lessThanOrEqualTo(80));
  });
}
