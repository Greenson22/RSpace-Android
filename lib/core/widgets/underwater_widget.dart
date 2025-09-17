// lib/core/widgets/underwater_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';

class UnderwaterWidget extends StatefulWidget {
  final int totalFish;
  final double speed;
  final bool isRunning;

  const UnderwaterWidget({
    super.key,
    this.totalFish = 15,
    this.speed = 1.0,
    this.isRunning = true,
  });

  @override
  State<UnderwaterWidget> createState() => _UnderwaterWidgetState();
}

class _UnderwaterWidgetState extends State<UnderwaterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Fish> _fishes;
  late Size _size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.isRunning) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _size = MediaQuery.of(context).size;
    _fishes = List.generate(
      widget.totalFish,
      (index) => Fish.random(_size, widget.speed),
    );
  }

  @override
  void didUpdateWidget(covariant UnderwaterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: UnderwaterPainter(
        fishes: _fishes,
        controller: _controller,
        speed: widget.speed,
      ),
    );
  }
}

class UnderwaterPainter extends CustomPainter {
  final List<Fish> fishes;
  final AnimationController controller;
  final double speed;

  UnderwaterPainter({
    required this.fishes,
    required this.controller,
    required this.speed,
  }) : super(repaint: controller);

  void _updateFishes(Size size) {
    for (var fish in fishes) {
      fish.swim(size, speed);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _updateFishes(size);
    for (var fish in fishes) {
      fish.draw(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant UnderwaterPainter oldDelegate) {
    return false;
  }
}

class Fish {
  double x;
  double y;
  double size;
  double velocityX;
  double velocityY;
  String bodyRight;
  String bodyLeft;
  Color color;
  bool isFacingRight;

  Fish({
    required this.x,
    required this.y,
    required this.size,
    required this.velocityX,
    required this.velocityY,
    required this.bodyRight,
    required this.bodyLeft,
    required this.color,
    required this.isFacingRight,
  });

  factory Fish.random(Size size, double speed) {
    final random = Random();
    final isFacingRight = random.nextBool();
    // ==> PERBAIKAN: Definisikan bentuk ikan untuk setiap arah
    final fishBodies = [
      {'right': '><(((º>', 'left': '<º)))><'},
      {'right': '><(((º>', 'left': '<º)))><'},
      {'right': '(º <', 'left': '> º)'},
    ];
    final selectedBody = fishBodies[random.nextInt(fishBodies.length)];

    return Fish(
      x: random.nextDouble() * size.width,
      y: random.nextDouble() * size.height,
      size: random.nextDouble() * 10 + 10,
      velocityX:
          (random.nextDouble() * 1.5 + 0.5) * speed * (isFacingRight ? 1 : -1),
      velocityY: (random.nextDouble() - 0.5) * 0.5 * speed,
      bodyRight: selectedBody['right']!,
      bodyLeft: selectedBody['left']!,
      color: HSLColor.fromAHSL(
        1.0,
        random.nextDouble() * 360,
        0.8,
        0.6,
      ).toColor(),
      isFacingRight: isFacingRight,
    );
  }

  void swim(Size size, double speed) {
    x += velocityX;
    y += velocityY;

    // Bounce off vertical walls
    if (x < -size.width * 0.2 || x > size.width * 1.2) {
      isFacingRight = !isFacingRight;
      velocityX *= -1;
    }
    // Bounce off horizontal walls
    if (y < 0 || y > size.height) {
      velocityY *= -1;
    }
  }

  void draw(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        // ==> PERBAIKAN: Pilih bentuk ikan berdasarkan arah
        text: isFacingRight ? bodyRight : bodyLeft,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: 'monospace',
          shadows: [
            Shadow(
              blurRadius: 3.0,
              color: color.withOpacity(0.5),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(x, y));
  }
}
