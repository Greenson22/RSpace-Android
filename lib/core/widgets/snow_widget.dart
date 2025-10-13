// lib/core/widgets/snow_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';

class SnowWidget extends StatefulWidget {
  final int totalSnow;
  final double speed;
  final bool isRunning;
  final Color snowColor;

  const SnowWidget({
    super.key,
    this.totalSnow = 150,
    this.speed = 0.4,
    this.isRunning = true,
    this.snowColor = Colors.white,
  });

  @override
  State<SnowWidget> createState() => _SnowWidgetState();
}

class _SnowWidgetState extends State<SnowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Snowflake> _snowflakes;
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
    _snowflakes = List.generate(
      widget.totalSnow,
      (index) => Snowflake.random(_size, widget.speed),
    );
  }

  @override
  void didUpdateWidget(covariant SnowWidget oldWidget) {
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
    // ==> PERBAIKAN DI SINI <==
    // Bungkus CustomPaint dengan IgnorePointer agar tidak memblokir sentuhan
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: SnowPainter(
          snowflakes: _snowflakes,
          snowColor: widget.snowColor,
          controller: _controller,
          speed: widget.speed,
        ),
      ),
    );
  }
}

class SnowPainter extends CustomPainter {
  final List<Snowflake> snowflakes;
  final Color snowColor;
  final AnimationController controller;
  final double speed;

  SnowPainter({
    required this.snowflakes,
    required this.snowColor,
    required this.controller,
    required this.speed,
  }) : super(repaint: controller);

  void _updateSnowflakes(Size size) {
    for (var snowflake in snowflakes) {
      snowflake.fall(size, speed);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _updateSnowflakes(size);

    final paint = Paint()
      ..color = snowColor
      ..style = PaintingStyle.fill;

    for (var snowflake in snowflakes) {
      canvas.drawCircle(
        Offset(snowflake.x, snowflake.y),
        snowflake.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SnowPainter oldDelegate) {
    return false;
  }
}

class Snowflake {
  double x;
  double y;
  double radius;
  double velocity;
  final double initialX;

  Snowflake(this.x, this.y, this.radius, this.velocity) : initialX = x;

  factory Snowflake.random(Size size, double speed) {
    final random = Random();
    return Snowflake(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
      random.nextDouble() * 2 + 1,
      random.nextDouble() * 0.5 + speed,
    );
  }

  void fall(Size size, double speed) {
    y += velocity;
    if (y > size.height) {
      y = -radius;
      x = Random().nextDouble() * size.width;
      radius = Random().nextDouble() * 2 + 1;
      velocity = Random().nextDouble() * 0.5 + speed;
    }
  }
}
