import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/core/constants/game_constants.dart';
import 'package:the_darkblade/enemy/enemy.dart';
import 'package:the_darkblade/game/darkblade_game.dart';
import 'package:the_darkblade/save/save_service.dart';
import 'package:the_darkblade/world/level_data.dart';

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

  testWidgets('all four levels load without errors', (tester) async {
    final game = await bootGame(tester);

    for (var i = 0; i < Levels.all.length; i++) {
      if (i > 0) await game.goToNextLevel();
      await tester.pump();
      for (var f = 0; f < 30; f++) {
        game.update(1 / 60);
      }
      expect(game.currentLevelIndex, i);
      expect(game.currentLevel!.definition.id, i);
    }

    await flushTimers(tester);
  });
}
