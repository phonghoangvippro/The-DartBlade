import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_darkblade/core/constants/game_constants.dart';
import 'package:the_darkblade/enemy/enemy.dart';
import 'package:the_darkblade/game/darkblade_game.dart';
import 'package:the_darkblade/player/player_state.dart';
import 'package:the_darkblade/save/save_service.dart';
import 'package:the_darkblade/world/level_data.dart';

/// Integration smoke tests: boot the real game, start a new run and step the
/// simulation to catch runtime errors in the component tree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget stub(BuildContext context, DarkbladeGame game) =>
      const SizedBox.shrink();

  Future<DarkbladeGame> bootGame(WidgetTester tester) async {
    // SaveService without init(): storage is a no-op, which is fine here.
    final game = DarkbladeGame(saveService: SaveService());
    await tester.pumpWidget(GameWidget<DarkbladeGame>(
      game: game,
      overlayBuilderMap: {
        OverlayIds.mainMenu: stub,
        OverlayIds.pauseMenu: stub,
        OverlayIds.settingsMenu: stub,
        OverlayIds.gameOver: stub,
        OverlayIds.victory: stub,
        OverlayIds.inventory: stub,
      },
    ));
    await tester.pump();
    await game.startNewGame();
    await tester.pump();
    // Flush component lifecycle events (mount queued children).
    game.update(0);
    return game;
  }

  /// Advances fake time so pending toast timers complete before teardown.
  Future<void> flushTimers(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 3));

  testWidgets('game boots and loads the first level', (tester) async {
    final game = await bootGame(tester);

    expect(game.phase, GamePhase.playing);
    expect(game.currentLevelIndex, 0);
    expect(game.currentLevel!.definition.name, 'Forgotten Forest');
    expect(game.currentLevel!.platforms, isNotEmpty);
    expect(game.player.isMounted, isTrue);

    await flushTimers(tester);
  });

  testWidgets('player falls onto the ground and idles', (tester) async {
    final game = await bootGame(tester);

    // Simulate ~1 second of gameplay.
    for (var i = 0; i < 60; i++) {
      game.update(1 / 60);
    }

    expect(game.player.isOnGround, isTrue);
    expect(game.player.state, PlayerState.idle);
    expect(game.player.isDead, isFalse);

    await flushTimers(tester);
  });

  testWidgets('enemies spawn and run their AI without errors',
      (tester) async {
    final game = await bootGame(tester);

    final enemies =
        game.currentLevel!.children.whereType<Enemy>().toList();
    expect(enemies.length,
        Levels.forgottenForest.enemies.length);

    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
    }
    // Still alive and simulating after 2 seconds.
    expect(game.phase, GamePhase.playing);

    await flushTimers(tester);
  });

  testWidgets('all five levels load without errors', (tester) async {
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
