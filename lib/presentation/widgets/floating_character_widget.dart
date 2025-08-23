// lib/presentation/widgets/floating_character_widget.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FloatingCharacter extends StatefulWidget {
  final bool isVisible;

  const FloatingCharacter({super.key, this.isVisible = true});

  @override
  State<FloatingCharacter> createState() => _FloatingCharacterState();
}

class _FloatingCharacterState extends State<FloatingCharacter>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _moveController;
  late Animation<double> _floatAnimation;
  late Animation<double> _moveAnimation;

  Timer? _animationTimer;
  Timer? _expressionTimer; // Timer baru untuk ekspresi wajah
  int _characterFrameIndex = 0;
  int _expressionIndex = 0; // Index baru untuk ekspresi
  bool _isFacingRight = true;
  final Random _random = Random();

  // Daftar "frame" animasi untuk gerakan (lambaian, kedipan)
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

  // Daftar "ekspresi" mata yang bisa diganti-ganti
  final List<Map<String, String>> _expressions = [
    {'eyes': '｡◕‿‿◕｡', 'wink': '｡◕‿‿-｡'}, // 0: Normal
    {'eyes': '｡^‿‿^｡', 'wink': '｡^‿‿-｡'}, // 1: Gembira
    {'eyes': '｡*‿‿*｡', 'wink': '｡*‿‿-｡'}, // 2: Berbinar
    {'eyes': '｡>‿‿<｡', 'wink': '｡>‿‿-｡'}, // 3: Fokus/Semangat
  ];

  // Fungsi untuk mendapatkan frame karakter yang sudah digabungkan dengan ekspresi
  String _getCurrentCharacterFrame() {
    final expression = _expressions[_expressionIndex];
    final baseFrames = _isFacingRight ? _baseFramesRight : _baseFramesLeft;
    String frame = baseFrames[_characterFrameIndex];

    // Ganti placeholder {eyes} dan {wink} dengan ekspresi yang aktif
    return frame
        .replaceAll('{eyes}', expression['eyes']!)
        .replaceAll('{wink}', expression['wink']!);
  }

  @override
  void initState() {
    super.initState();
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
      _startExpressionChange(); // Mulai timer ekspresi
    }
  }

  // Timer untuk animasi lambaian/kedipan (interval cepat & tetap)
  void _startCharacterAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          _characterFrameIndex =
              (_characterFrameIndex + 1) % _baseFramesRight.length;
        });
      }
    });
  }

  // Timer baru untuk perubahan ekspresi (interval lambat & acak)
  void _startExpressionChange() {
    _expressionTimer?.cancel();
    _expressionTimer = Timer.periodic(
      // Durasi acak antara 3 sampai 8 detik
      Duration(seconds: _random.nextInt(6) + 3),
      (timer) {
        if (mounted) {
          setState(() {
            // Pilih ekspresi baru yang berbeda dari yang sekarang
            int newIndex;
            do {
              newIndex = _random.nextInt(_expressions.length);
            } while (newIndex == _expressionIndex);
            _expressionIndex = newIndex;
          });
        }
      },
    );
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
      } else {
        _floatController.stop();
        _moveController.stop();
        _animationTimer?.cancel();
        _expressionTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _moveController.dispose();
    _animationTimer?.cancel();
    _expressionTimer?.cancel();
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
            character: _getCurrentCharacterFrame(), // Gunakan fungsi baru
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

  CharacterPainter({
    required this.floatAnimationValue,
    required this.moveAnimationValue,
    required this.character,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
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
    final textSpan = TextSpan(text: character, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double padding = 20;
    final startX =
        padding +
        (size.width - textPainter.width - (2 * padding)) * moveAnimationValue;
    final startY =
        padding +
        (size.height - textPainter.height - (2 * padding)) *
            floatAnimationValue;

    textPainter.paint(canvas, Offset(startX, startY));
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    return floatAnimationValue != oldDelegate.floatAnimationValue ||
        moveAnimationValue != oldDelegate.moveAnimationValue ||
        character != oldDelegate.character;
  }
}
