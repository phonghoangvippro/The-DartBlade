import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Animation;

import '../core/constants/game_constants.dart';
import '../game/darkblade_game.dart';

class DialogueLine {
  final String speaker;
  final String text;
  final Color color;

  const DialogueLine({
    required this.speaker,
    required this.text,
    this.color = const Color(0xFFE0C9FF),
  });
}

class DialogueSequence extends Component with HasGameReference<DarkbladeGame> {
  final List<DialogueLine> _lines;
  final VoidCallback? onComplete;
  int _currentIndex = 0;
  double _charTimer = 0;
  int _charsToShow = 0;
  bool _finished = false;
  double _timer = 0;

  DialogueSequence({required List<DialogueLine> lines, this.onComplete})
    : _lines = lines {
    priority = GameConstants.priorityFx + 100;
  }

  @override
  void onMount() {
    super.onMount();
    _currentIndex = 0;
    _charTimer = 0;
    _charsToShow = 0;
    _finished = false;
    _timer = 0;
  }

  void advance() {
    if (_finished) {
      removeFromParent();
      onComplete?.call();
      return;
    }
    if (_charsToShow < _lines[_currentIndex].text.length) {
      _charsToShow = _lines[_currentIndex].text.length;
      return;
    }
    _currentIndex++;
    _charsToShow = 0;
    _charTimer = 0;
    if (_currentIndex >= _lines.length) {
      _finished = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_currentIndex >= _lines.length) {
      _finished = true;
      return;
    }
    _charTimer += dt * 40;
    _charsToShow = _charsToShow + _charTimer.floor();
    _charTimer -= _charTimer.floor();
    if (_charsToShow > _lines[_currentIndex].text.length) {
      _charsToShow = _lines[_currentIndex].text.length;
    }
  }

  bool get isCurrentlyFinished =>
      _currentIndex >= _lines.length ||
      (_currentIndex == _lines.length - 1 &&
          _charsToShow >= _lines[_currentIndex].text.length);

  @override
  void render(Canvas canvas) {
    if (_finished) return;
    final line = _lines[_currentIndex];
    final viewportSize = game.camera.viewport.size;
    final w = viewportSize.x;
    final h = viewportSize.y;

    final bgPaint = Paint()..color = const Color(0xCC0D0D14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, h - 140, w - 80, 110),
        const Radius.circular(8),
      ),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, h - 140, w - 80, 110),
        const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFF7B2FF2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final speakerStyle = TextStyle(
      color: Color(line.color.toARGB32()),
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );
    final textStyle = TextStyle(
      color: const Color(0xFFE8E0F0).withValues(alpha: 0.9),
      fontSize: 14,
      height: 1.4,
    );

    canvas.save();
    canvas.translate(56, h - 122);
    final speakerPb = TextPainter(
      text: TextSpan(text: line.speaker, style: speakerStyle),
      textDirection: TextDirection.ltr,
    );
    speakerPb.layout(maxWidth: w - 130);
    speakerPb.paint(canvas, Offset.zero);

    final displayText = line.text.substring(
      0,
      _charsToShow.clamp(0, line.text.length),
    );
    final textPb = TextPainter(
      text: TextSpan(text: displayText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPb.layout(maxWidth: w - 130);
    textPb.paint(canvas, Offset(0, 26));

    if (isCurrentlyFinished) {
      final continueAlpha = 0.6 + sin(_timer * 3) * 0.3;
      final continuePb = TextPainter(
        text: TextSpan(
          text: 'Press SPACE / Tap to continue...',
          style: TextStyle(
            color: const Color(0xFF7B2FF2).withValues(alpha: continueAlpha),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      continuePb.layout(maxWidth: w - 130);
      continuePb.paint(canvas, Offset(w - 210, 80));
    }

    canvas.restore();
  }
}

class IntroCutscene extends Component with HasGameReference<DarkbladeGame> {
  static const _scenes = [
    _SceneData(
      'Lời Nguyền Của Ánh Sáng',
      'Khi ánh sáng quá chói, nó sinh ra cái bóng đen nhất.\nSolarius không hủy diệt Abyss. Nó chỉ giam cầm bóng tối.',
      'Mỗi thế kỷ, một người mang phải chết để hàn lại phong ấn.',
      Color(0xFFB388FF),
    ),
    _SceneData(
      'Tội Lỗi Của Một Người Cha',
      'Khi con gái bị chọn làm vật hiến tế, Varkhan đã chống lại định mệnh.\nÔng hợp nhất Solarius với Lõi Bóng Tối.',
      'DARKBLADE ra đời. Mặt trời tắt.\nBầu trời hóa máu.',
      Color(0xFFFF4444),
    ),
    _SceneData(
      'Đứa Trẻ Không Tên',
      'Nhiều năm sau, một đứa trẻ được tìm thấy\nbên xác một hiệp sĩ, tay nắm mảnh vỡ Solarius.',
      'Người dân gọi cậu là Ash.\nKhông ai biết mảnh sáng ấy đang giữ thứ gì trong máu cậu.',
      Color(0xFFE0C9FF),
    ),
    _SceneData(
      'Ngôi Làng Tro Tàn',
      'Mưa. Sấm chớp. Quái vật tràn vào làng.\nCha nuôi của Ash ngã xuống cùng một Mảnh Darkblade.',
      'Khi Ash chạm vào nó... bóng tối bùng lên từ chính máu cậu.',
      Color(0xFFFF6633),
    ),
    _SceneData(
      'THE DARKBLADE',
      'Số phận không gọi tên ngươi.\nNgươi CHÍNH LÀ số phận.',
      '',
      Color(0xFF7B2FF2),
    ),
  ];

  final VoidCallback? onComplete;
  double _timer = 0;
  int _sceneIndex = 0;
  double _fadeAlpha = 0;
  bool _fadeOut = false;
  bool _finished = false;

  IntroCutscene({this.onComplete}) {
    priority = GameConstants.priorityFx + 200;
  }

  @override
  void onMount() {
    super.onMount();
    _timer = 0;
    _sceneIndex = 0;
    _fadeAlpha = 0;
    _fadeOut = false;
    _finished = false;
  }

  void advance() {
    if (_sceneIndex >= _scenes.length) {
      _finish();
      return;
    }
    _fadeOut = true;
  }

  void _finish() {
    _finished = true;
    game.resumeEngine();
    removeFromParent();
    onComplete?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) return;
    if (_fadeOut) {
      _fadeAlpha -= dt * 1.5;
      if (_fadeAlpha <= 0) {
        _fadeAlpha = 0;
        _sceneIndex++;
        _timer = 0;
        _fadeOut = false;
        if (_sceneIndex >= _scenes.length) {
          _finish();
          return;
        }
      }
    } else if (_fadeAlpha < 1) {
      _fadeAlpha = (_fadeAlpha + dt * 1.25).clamp(0.0, 1.0);
    } else {
      _timer += dt;
      final scene = _scenes[_sceneIndex];
      final characterCount = scene.line1.length + scene.line2.length;
      final readingTime = (characterCount / 18).clamp(6.0, 10.0);
      if (_timer >= readingTime) _fadeOut = true;
    }
  }

  @override
  void render(Canvas canvas) {
    final viewportSize = game.camera.viewport.size;
    final w = viewportSize.x;
    final h = viewportSize.y;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF000000),
    );

    final scene = _scenes[_sceneIndex.clamp(0, _scenes.length - 1)];
    final displayAlpha = _fadeAlpha;

    if (displayAlpha > 0.01) {
      canvas.save();
      canvas.translate(0, 0);

      final titleStyle = TextStyle(
        color: Color(scene.color.toARGB32()).withValues(alpha: displayAlpha),
        fontSize: _sceneIndex == 4 ? 36 : 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 6,
      );
      final subStyle = TextStyle(
        color: const Color(0xFFE8E0F0).withValues(alpha: displayAlpha * 0.85),
        fontSize: 15,
        height: 1.6,
      );
      final subStyle2 = TextStyle(
        color: const Color(0xFFB0A0C0).withValues(alpha: displayAlpha * 0.7),
        fontSize: 13,
        height: 1.5,
      );

      var y = h * 0.2;
      final titlePb = TextPainter(
        text: TextSpan(text: scene.title, style: titleStyle),
        textDirection: TextDirection.ltr,
      );
      titlePb.layout(maxWidth: w - 120);
      titlePb.paint(canvas, Offset((w - titlePb.width) / 2, y));
      y += titlePb.height + 30;

      if (scene.line1.isNotEmpty) {
        final line1Pb = TextPainter(
          text: TextSpan(text: scene.line1, style: subStyle),
          textDirection: TextDirection.ltr,
        );
        line1Pb.layout(maxWidth: w - 160);
        line1Pb.paint(canvas, Offset((w - line1Pb.width) / 2, y));
        y += line1Pb.height + 8;
      }

      if (scene.line2.isNotEmpty) {
        final line2Pb = TextPainter(
          text: TextSpan(text: scene.line2, style: subStyle2),
          textDirection: TextDirection.ltr,
        );
        line2Pb.layout(maxWidth: w - 160);
        line2Pb.paint(canvas, Offset((w - line2Pb.width) / 2, y));
      }

      canvas.restore();
    }
  }
}

class _SceneData {
  final String title;
  final String line1;
  final String line2;
  final Color color;
  const _SceneData(this.title, this.line1, this.line2, this.color);
}
