// lib/core/widgets/snake_widget.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum Direction { up, down, left, right }

class SnakeWidget extends StatefulWidget {
  final int boxSize;
  final int speed; // milliseconds between moves

  const SnakeWidget({super.key, this.boxSize = 20, this.speed = 200});

  @override
  State<SnakeWidget> createState() => _SnakeWidgetState();
}

class _SnakeWidgetState extends State<SnakeWidget> {
  List<Point<int>> _snake = [];
  Point<int>? _food;
  Direction _direction = Direction.right;
  Timer? _timer;
  late Size _size;
  late int _gridWidth;
  late int _gridHeight;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Pindahkan inisialisasi ke sini dan pastikan dijalankan setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _size = MediaQuery.of(context).size;
        _gridWidth = _size.width ~/ widget.boxSize;
        _gridHeight = _size.height ~/ widget.boxSize;
        _startGame();
      }
    });
  }

  void _startGame() {
    // Reset snake position to the center
    _snake = [
      Point(_gridWidth ~/ 2, _gridHeight ~/ 2),
      Point(_gridWidth ~/ 2 - 1, _gridHeight ~/ 2),
      Point(_gridWidth ~/ 2 - 2, _gridHeight ~/ 2),
    ];
    _direction = Direction.right;
    _generateFood();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: widget.speed), (timer) {
      if (mounted) {
        _move();
      }
    });
  }

  void _generateFood() {
    int x = _random.nextInt(_gridWidth);
    int y = _random.nextInt(_gridHeight);
    _food = Point(x, y);

    // Ensure food doesn't spawn on the snake
    for (var segment in _snake) {
      if (segment.x == x && segment.y == y) {
        _generateFood();
        return;
      }
    }
  }

  void _changeDirectionRandomly() {
    List<Direction> possibleDirections = [];
    if (_direction != Direction.down) possibleDirections.add(Direction.up);
    if (_direction != Direction.up) possibleDirections.add(Direction.down);
    if (_direction != Direction.right) possibleDirections.add(Direction.left);
    if (_direction != Direction.left) possibleDirections.add(Direction.right);

    _direction = possibleDirections[_random.nextInt(possibleDirections.length)];
  }

  void _move() {
    if (!mounted) return;

    // AI logic: 80% chance to continue in the same direction
    if (_random.nextInt(100) > 80) {
      _changeDirectionRandomly();
    }

    setState(() {
      Point<int> head = _snake.first;
      Point<int> newHead;

      switch (_direction) {
        case Direction.up:
          newHead = Point(head.x, head.y - 1);
          break;
        case Direction.down:
          newHead = Point(head.x, head.y + 1);
          break;
        case Direction.left:
          newHead = Point(head.x - 1, head.y);
          break;
        case Direction.right:
          newHead = Point(head.x + 1, head.y);
          break;
      }

      // Wall collision detection and wrap around
      if (newHead.x >= _gridWidth) newHead = Point(0, newHead.y);
      if (newHead.x < 0) newHead = Point(_gridWidth - 1, newHead.y);
      if (newHead.y >= _gridHeight) newHead = Point(newHead.x, 0);
      if (newHead.y < 0) newHead = Point(newHead.x, _gridHeight - 1);

      // Self-collision detection
      for (var segment in _snake) {
        if (newHead == segment) {
          _startGame(); // Restart game on collision
          return;
        }
      }

      _snake.insert(0, newHead);

      if (newHead == _food) {
        _generateFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tambahkan kondisi untuk menampilkan loading jika grid belum siap
    if (_snake.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _SnakePainter(
        snake: _snake,
        food: _food,
        boxSize: widget.boxSize.toDouble(),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int>? food;
  final double boxSize;

  _SnakePainter({required this.snake, this.food, required this.boxSize});

  @override
  void paint(Canvas canvas, Size size) {
    final snakePaint = Paint()..color = Colors.green;
    final foodPaint = Paint()..color = Colors.red;

    // Draw snake
    for (var segment in snake) {
      canvas.drawRect(
        Rect.fromLTWH(
          segment.x * boxSize,
          segment.y * boxSize,
          boxSize,
          boxSize,
        ),
        snakePaint,
      );
    }

    // Draw food
    if (food != null) {
      canvas.drawRect(
        Rect.fromLTWH(food!.x * boxSize, food!.y * boxSize, boxSize, boxSize),
        foodPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
