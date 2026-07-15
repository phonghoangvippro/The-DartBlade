class GameConstants {
  GameConstants._();

  static const double viewWidth = 960;
  static const double viewHeight = 540;
  static const double tileSize = 32;

  static const int priorityBackground = -10;
  static const int priorityPlatform = 0;
  static const int priorityPickup = 5;
  static const int priorityEnemy = 10;
  static const int priorityPlayer = 20;
  static const int priorityProjectile = 25;
  static const int priorityFx = 30;
}

class OverlayIds {
  OverlayIds._();

  static const String mainMenu = 'main_menu';
  static const String pauseMenu = 'pause_menu';
  static const String settingsMenu = 'settings_menu';
  static const String gameOver = 'game_over';
  static const String victory = 'victory';
  static const String inventory = 'inventory';
  static const String dialogue = 'dialogue';
  static const String chapterTitle = 'chapter_title';
}
