// lib/presentation/widgets/floating_character_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';

class FloatingCharacter extends StatefulWidget {
  final bool isVisible;

  const FloatingCharacter({super.key, this.isVisible = true});

  @override
  State<FloatingCharacter> createState() => _FloatingCharacterState();
}

class _FloatingCharacterState extends State<FloatingCharacter>
    with TickerProviderStateMixin {
  late AnimationController _floatController; // Untuk naik-turun
  late AnimationController _moveController; // Untuk kiri-kanan
  late Animation<double> _floatAnimation;
  late Animation<double> _moveAnimation;

  Timer? _animationTimer;
  int _characterFrameIndex = 0;
  bool _isFacingRight = true;

  // Daftar frame animasi untuk menghadap ke kanan
  final List<String> _framesRight = [
    '(づ｡◕‿‿◕｡)づ', // 0: Normal
    '(づ｡◕‿‿◕｡)づ', // 1: Normal
    '(づ｡◕‿‿-｡)づ', // 2: Berkedip
    '(づ｡◕‿‿◕｡)づ', // 3: Normal
    '~(づ｡◕‿‿◕｡)づ', // 4: Melambai 1
    '~~(づ｡◕‿‿◕｡)づ', // 5: Melambai 2
    '~(づ｡◕‿‿◕｡)づ', // 6: Melambai 1
    '(づ｡◕‿‿◕｡)づ', // 7: Normal
  ];

  // Daftar frame animasi untuk menghadap ke kiri
  final List<String> _framesLeft = [
    '٩(｡◕‿‿◕｡٩)', // 0: Normal
    '٩(｡◕‿‿◕｡٩)', // 1: Normal
    '٩(｡-‿‿◕｡٩)', // 2: Berkedip
    '٩(｡◕‿‿◕｡٩)', // 3: Normal
    '٩(｡◕‿‿◕｡٩)~', // 4: Melambai 1
    '٩(｡◕‿‿◕｡٩)~~', // 5: Melambai 2
    '٩(｡◕‿‿◕｡٩)~', // 6: Melambai 1
    '٩(｡◕‿‿◕｡٩)', // 7: Normal
  ];

  @override
  void initState() {
    super.initState();
    // Kontroler untuk gerakan vertikal (mengambang)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 10,
      ), // Durasi yang lebih lama untuk pergerakan vertikal
    );
    // Diubah: Tween sekarang dari 0 ke 1 untuk menutupi seluruh tinggi layar
    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Kontroler untuk gerakan horizontal (kiri-kanan)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _moveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );

    // Listener untuk membalik arah ketika sampai di tujuan
    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isFacingRight = false);
        _moveController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _isFacingRight = true);
        _moveController.forward();
      }
    });

    // Listener baru untuk gerakan vertikal
    _floatController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _floatController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _floatController.forward();
      }
    });

    if (widget.isVisible) {
      _floatController.forward(); // Mulai gerakan vertikal
      _moveController.forward(); // Mulai gerakan horizontal
      _startCharacterAnimation();
    }
  }

  void _startCharacterAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          _characterFrameIndex =
              (_characterFrameIndex + 1) % _framesRight.length;
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
      } else {
        _floatController.stop();
        _moveController.stop();
        _animationTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _moveController.dispose();
    _animationTimer?.cancel();
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
            character: _isFacingRight
                ? _framesRight[_characterFrameIndex]
                : _framesLeft[_characterFrameIndex],
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

    // Kalkulasi posisi X dan Y menggunakan nilai animasi
    // Posisi horizontal: bergerak dari kiri ke kanan
    final startX =
        padding +
        (size.width - textPainter.width - (2 * padding)) * moveAnimationValue;

    // Posisi vertikal: bergerak dari atas ke bawah
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
