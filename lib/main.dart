import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/game_constants.dart';
import 'game/darkblade_game.dart';
import 'save/save_service.dart';
import 'ui/game_over_menu.dart';
import 'ui/hud.dart';
import 'ui/inventory_menu.dart';
import 'ui/main_menu.dart';
import 'ui/pause_menu.dart';
import 'ui/settings_menu.dart';
import 'ui/touch_controls.dart';
import 'ui/victory_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final saveService = SaveService();
  await saveService.init();

  runApp(DarkbladeApp(saveService: saveService));
}

class DarkbladeApp extends StatefulWidget {
  const DarkbladeApp({super.key, required this.saveService});

  final SaveService saveService;

  @override
  State<DarkbladeApp> createState() => _DarkbladeAppState();
}

class _DarkbladeAppState extends State<DarkbladeApp> {
  late final DarkbladeGame _game = DarkbladeGame(
    saveService: widget.saveService,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Darkblade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget<DarkbladeGame>(
              game: _game,
              overlayBuilderMap: {
                OverlayIds.mainMenu: (context, game) => MainMenu(game: game),
                OverlayIds.pauseMenu: (context, game) => PauseMenu(game: game),
                OverlayIds.settingsMenu: (context, game) =>
                    SettingsMenu(game: game),
                OverlayIds.gameOver: (context, game) =>
                    GameOverMenu(game: game),
                OverlayIds.victory: (context, game) => VictoryMenu(game: game),
                OverlayIds.inventory: (context, game) =>
                    InventoryMenu(game: game),
              },
              loadingBuilder: (context) => const Center(
                child: CircularProgressIndicator(color: Color(0xFF7B2FF2)),
              ),
            ),
            Positioned.fill(child: Hud(game: _game)),
            Positioned.fill(child: TouchControls(game: _game)),
          ],
        ),
      ),
    );
  }
}
