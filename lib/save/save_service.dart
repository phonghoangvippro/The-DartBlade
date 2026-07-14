import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../core/logger/game_logger.dart';
import 'save_model.dart';

/// Persists [SaveModel] via Hive (FR-031, FR-032).
///
/// Save target is < 0.5s (NFR): serialization is a tiny JSON string so this
/// is comfortably met.
class SaveService {
  static const String _boxName = 'darkblade_save';
  static const String _slotKey = 'slot_0';

  Box<String>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  bool get hasSave => _box?.containsKey(_slotKey) ?? false;

  Future<void> save(SaveModel model) async {
    try {
      await _box?.put(_slotKey, jsonEncode(model.toJson()));
      GameLogger.info('Save', 'Game saved (level ${model.currentLevel})');
    } catch (e) {
      GameLogger.error('Save', 'Failed to save', e);
    }
  }

  SaveModel? load() {
    try {
      final raw = _box?.get(_slotKey);
      if (raw == null) return null;
      return SaveModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (e) {
      GameLogger.error('Save', 'Failed to load', e);
      return null;
    }
  }

  Future<void> deleteSave() async {
    await _box?.delete(_slotKey);
  }
}
