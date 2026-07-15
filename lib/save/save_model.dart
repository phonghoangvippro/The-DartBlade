class SaveModel {
  SaveModel({
    required this.currentLevel,
    required this.playerX,
    required this.playerY,
    required this.hp,
    required this.mana,
    required this.stamina,
    required this.souls,
    required this.inventoryJson,
    required this.defeatedBosses,
    this.defeatedEnemies = const [],
    this.unlockDash = true,
    this.timestamp,
  });

  final int currentLevel;
  final double playerX;
  final double playerY;
  final double hp;
  final double mana;
  final double stamina;
  final int souls;
  final Map<String, dynamic> inventoryJson;
  final List<int> defeatedBosses;
  final List<String> defeatedEnemies;
  final bool unlockDash;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
    'version': 3,
    'currentLevel': currentLevel,
    'playerX': playerX,
    'playerY': playerY,
    'hp': hp,
    'mana': mana,
    'stamina': stamina,
    'souls': souls,
    'inventory': inventoryJson,
    'defeatedBosses': defeatedBosses,
    'defeatedEnemies': defeatedEnemies,
    'unlockDash': unlockDash,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
  };

  static SaveModel fromJson(Map<String, dynamic> json) => SaveModel(
    currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 0,
    playerX: (json['playerX'] as num?)?.toDouble() ?? 0,
    playerY: (json['playerY'] as num?)?.toDouble() ?? 0,
    hp: (json['hp'] as num?)?.toDouble() ?? 100,
    mana: (json['mana'] as num?)?.toDouble() ?? 50,
    stamina: (json['stamina'] as num?)?.toDouble() ?? 100,
    souls: (json['souls'] as num?)?.toInt() ?? 0,
    inventoryJson: Map<String, dynamic>.from(
      json['inventory'] as Map? ?? const {},
    ),
    defeatedBosses: List<int>.from(
      (json['defeatedBosses'] as List? ?? const []).map(
        (e) => (e as num).toInt(),
      ),
    ),
    defeatedEnemies: List<String>.from(
      (json['defeatedEnemies'] as List? ?? const []).map((e) => e.toString()),
    ),
    unlockDash: (json['unlockDash'] as bool?) ?? true,
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String)
        : null,
  );
}
