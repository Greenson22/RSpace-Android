// lib/presentation/widgets/floating_character_widget.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/models/discussion_model.dart';
import '../../data/services/path_service.dart';

class FloatingCharacter extends StatefulWidget {
  final bool isVisible;

  const FloatingCharacter({super.key, this.isVisible = true});

  @override
  State<FloatingCharacter> createState() => _FloatingCharacterState();
}

class _FloatingCharacterState extends State<FloatingCharacter>
    with TickerProviderStateMixin {
  // Kontroler Animasi
  late AnimationController _floatController;
  late AnimationController _moveController;
  late Animation<double> _floatAnimation;
  late Animation<double> _moveAnimation;

  // Timer
  Timer? _animationTimer;
  Timer? _expressionTimer;
  Timer? _speechTimer;

  // State Karakter
  int _characterFrameIndex = 0;
  int _expressionIndex = 0;
  bool _isFacingRight = true;
  final Random _random = Random();

  // State Gelembung Ucapan
  bool _isSpeaking = false;
  String _speechBubbleText = '';

  // Daftar "frame" animasi gerakan
  final List<String> _baseFramesRight = [
    '(づ{eyes})づ',
    '(づ{eyes})づ',
    '(づ{wink})づ',
    '(づ{eyes})づ',
    '~(づ{eyes})づ',
    '~~(づ{eyes})づ',
    '~(づ{eyes})づ',
    '(づ{eyes})づ',
  ];
  final List<String> _baseFramesLeft = [
    '٩({eyes}٩)',
    '٩({eyes}٩)',
    '٩({wink}٩)',
    '٩({eyes}٩)',
    '٩({eyes}٩)~',
    '٩({eyes}٩)~~',
    '٩({eyes}٩)~',
    '٩({eyes}٩)',
  ];

  // Daftar ekspresi mata
  final List<Map<String, String>> _expressions = [
    {'eyes': '｡◕‿‿◕｡', 'wink': '｡◕‿‿-｡'}, // Normal
    {'eyes': '｡^‿‿^｡', 'wink': '｡^‿‿-｡'}, // Gembira
    {'eyes': '｡*‿‿*｡', 'wink': '｡*‿‿-｡'}, // Berbinar
    {'eyes': '｡>‿‿<｡', 'wink': '｡>‿‿-｡'}, // Fokus
    {'eyes': '｡ºωº｡', 'wink': '｡-ω-｡'}, // Mulut bicara/kaget
  ];

  // Kumpulan kalimat untuk Flo, akan digabung dengan data diskusi
  final List<String> _phrases = [
    "Semangat ya!",
    "Jangan lupa istirahat...",
    "Sudah cek 'My Tasks' hari ini?",
    "Ada yang bisa dibantu?",
    "Ayo kita selesaikan ini!",
    "Kamu pasti bisa!",
  ];

  String _getCurrentCharacterFrame() {
    final expression = _isSpeaking
        ? _expressions[4]
        : _expressions[_expressionIndex];
    final baseFrames = _isFacingRight ? _baseFramesRight : _baseFramesLeft;
    String frame = baseFrames[_characterFrameIndex];
    return frame
        .replaceAll('{eyes}', expression['eyes']!)
        .replaceAll('{wink}', expression['wink']!);
  }

  @override
  void initState() {
    super.initState();
    // Inisialisasi Kontroler Animasi
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );

    // Listeners untuk membalik arah
    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isFacingRight = false);
        _moveController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _isFacingRight = true);
        _moveController.forward();
      }
    });
    _floatController.addStatusListener((status) {
      if (status == AnimationStatus.completed)
        _floatController.reverse();
      else if (status == AnimationStatus.dismissed)
        _floatController.forward();
    });

    if (widget.isVisible) {
      _floatController.forward();
      _moveController.forward();
      _startCharacterAnimation();
      _startExpressionChange();
      _initializeSpeech(); // Panggil fungsi inisialisasi baru
    }
  }

  // Fungsi baru untuk memuat data diskusi dan memulai timer bicara
  Future<void> _initializeSpeech() async {
    await _loadDiscussionPhrases();
    _startSpeech();
  }

  // Fungsi baru untuk memuat judul diskusi dari file
  Future<void> _loadDiscussionPhrases() async {
    final pathService = PathService();
    final List<String> discussionTitles = [];
    try {
      final topicsPath = await pathService.topicsPath;
      final topicsDir = Directory(topicsPath);

      if (!await topicsDir.exists()) return;

      final topicEntities = topicsDir.listSync();
      for (var topicEntity in topicEntities) {
        if (topicEntity is Directory) {
          final subjectFiles = topicEntity.listSync().whereType<File>().where(
            (file) =>
                file.path.endsWith('.json') &&
                !path.basename(file.path).contains('config'),
          );

          for (final subjectFile in subjectFiles) {
            final jsonString = await subjectFile.readAsString();
            if (jsonString.isEmpty) continue;

            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            final contentList = jsonData['content'] as List<dynamic>? ?? [];

            for (var item in contentList) {
              final discussion = Discussion.fromJson(item);
              // Tambahkan hanya jika tidak punya points
              if (discussion.points.isEmpty && !discussion.finished) {
                discussionTitles.add(discussion.discussion);
              }
            }
          }
        }
      }
      // Gabungkan dengan frasa default
      if (discussionTitles.isNotEmpty) {
        _phrases.addAll(discussionTitles);
      }
    } catch (e) {
      debugPrint("Error loading discussion titles for Flo: $e");
      // Jika error, akan menggunakan frasa default saja
    }
  }

  void _startCharacterAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) {
      if (mounted)
        setState(
          () => _characterFrameIndex =
              (_characterFrameIndex + 1) % _baseFramesRight.length,
        );
    });
  }

  void _startExpressionChange() {
    _expressionTimer?.cancel();
    _expressionTimer = Timer.periodic(
      Duration(seconds: _random.nextInt(6) + 3),
      (timer) {
        if (mounted && !_isSpeaking) {
          setState(() {
            int newIndex;
            do {
              newIndex = _random.nextInt(4);
            } while (newIndex == _expressionIndex);
            _expressionIndex = newIndex;
          });
        }
      },
    );
  }

  void _startSpeech() {
    _speechTimer?.cancel();
    _speechTimer = Timer.periodic(Duration(seconds: _random.nextInt(15) + 10), (
      timer,
    ) {
      if (mounted && !_isSpeaking && _phrases.isNotEmpty) {
        setState(() {
          _isSpeaking = true;
          _speechBubbleText = _phrases[_random.nextInt(_phrases.length)];
        });
        Future.delayed(const Duration(seconds: 6), () {
          if (mounted) setState(() => _isSpeaking = false);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant FloatingCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _floatController.forward();
        _moveController.forward();
        _startCharacterAnimation();
        _startExpressionChange();
        _initializeSpeech();
      } else {
        _floatController.stop();
        _moveController.stop();
        _animationTimer?.cancel();
        _expressionTimer?.cancel();
        _speechTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _moveController.dispose();
    _animationTimer?.cancel();
    _expressionTimer?.cancel();
    _speechTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _moveAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: CharacterPainter(
            floatAnimationValue: _floatAnimation.value,
            moveAnimationValue: _moveAnimation.value,
            character: _getCurrentCharacterFrame(),
            isSpeaking: _isSpeaking,
            speechText: _speechBubbleText,
            isFacingRight: _isFacingRight,
          ),
        );
      },
    );
  }
}

class CharacterPainter extends CustomPainter {
  final double floatAnimationValue;
  final double moveAnimationValue;
  final String character;
  final bool isSpeaking;
  final String speechText;
  final bool isFacingRight;

  CharacterPainter({
    required this.floatAnimationValue,
    required this.moveAnimationValue,
    required this.character,
    required this.isSpeaking,
    required this.speechText,
    required this.isFacingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final characterTextStyle = TextStyle(
      color: Colors.black.withOpacity(0.8),
      fontSize: 24,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(2, 2),
        ),
      ],
    );
    final characterTextSpan = TextSpan(
      text: character,
      style: characterTextStyle,
    );
    final characterTextPainter = TextPainter(
      text: characterTextSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final double padding = 20;
    final characterX =
        padding +
        (size.width - characterTextPainter.width - (2 * padding)) *
            moveAnimationValue;
    final characterY =
        padding +
        (size.height - characterTextPainter.height - (2 * padding)) *
            floatAnimationValue;
    final characterPosition = Offset(characterX, characterY);

    characterTextPainter.paint(canvas, characterPosition);

    if (isSpeaking) {
      final speechTextStyle = TextStyle(color: Colors.black87, fontSize: 14);
      final speechTextSpan = TextSpan(text: speechText, style: speechTextStyle);
      final speechTextPainter = TextPainter(
        text: speechTextSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 150);

      final bubblePadding = const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      );
      final bubbleWidth =
          speechTextPainter.width + bubblePadding.left + bubblePadding.right;
      final bubbleHeight =
          speechTextPainter.height + bubblePadding.top + bubblePadding.bottom;
      final bubbleRRect = RRect.fromLTRBR(
        0,
        0,
        bubbleWidth,
        bubbleHeight,
        const Radius.circular(12),
      );

      final bubbleX =
          characterPosition.dx +
          (characterTextPainter.width / 2) -
          (bubbleWidth / 2);
      final bubbleY = characterPosition.dy - bubbleHeight - 10;

      final Paint bubblePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final Path bubblePath = Path()..addRRect(bubbleRRect);

      final tailPath = Path();
      if (isFacingRight) {
        tailPath.moveTo(bubbleWidth * 0.3, bubbleHeight);
        tailPath.lineTo(bubbleWidth * 0.4, bubbleHeight + 10);
        tailPath.lineTo(bubbleWidth * 0.5, bubbleHeight);
      } else {
        tailPath.moveTo(bubbleWidth * 0.7, bubbleHeight);
        tailPath.lineTo(bubbleWidth * 0.6, bubbleHeight + 10);
        tailPath.lineTo(bubbleWidth * 0.5, bubbleHeight);
      }
      tailPath.close();
      bubblePath.addPath(tailPath, Offset.zero);

      canvas.save();
      canvas.translate(bubbleX, bubbleY);
      canvas.drawShadow(bubblePath, Colors.black, 5.0, true);
      canvas.drawPath(bubblePath, bubblePaint);
      speechTextPainter.paint(
        canvas,
        Offset(bubblePadding.left, bubblePadding.top),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    return floatAnimationValue != oldDelegate.floatAnimationValue ||
        moveAnimationValue != oldDelegate.moveAnimationValue ||
        character != oldDelegate.character ||
        isSpeaking != oldDelegate.isSpeaking;
  }
}
