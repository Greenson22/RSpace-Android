// lib/features/snake_game/presentation/widgets/snake_game_widget.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/snake_game_provider.dart';
import '../../domain/snake_ann.dart';
import '../../infrastructure/snake_game_service.dart';

enum Direction { up, down, left, right }

class Snake {
  List<Point<int>> body;
  Direction direction;
  NeuralNetwork brain;
  int lifetime = 0;
  int score = 0;
  double fitness = 0;
  bool isDead = false;

  Snake(Point<int> start, this.brain)
    : body = [start, Point(start.x - 1, start.y), Point(start.x - 2, start.y)],
      direction = Direction.right;

  void calculateFitness() {
    fitness =
        lifetime.toDouble() +
        (pow(2, score) + pow(score, 2.1) * 500) -
        (pow(0.25, lifetime) * pow(score, 1.2));
    fitness = max(0, fitness);
  }
}

class SnakeGameWidget extends StatefulWidget {
  final bool trainingMode;

  const SnakeGameWidget({super.key, this.trainingMode = false});

  @override
  State<SnakeGameWidget> createState() => _SnakeGameWidgetState();
}

class _SnakeGameWidgetState extends State<SnakeGameWidget> {
  static const double MUTATION_RATE = 0.05;

  List<Snake> _population = [];
  Snake? _bestSnake;
  Point<int>? _food;
  Timer? _gameTimer;
  Timer? _trainingDurationTimer;
  late Size _size;
  late int _gridWidth;
  late int _gridHeight;
  final Random _random = Random();
  int _generation = 1;
  final SnakeGameService _gameService = SnakeGameService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _size = MediaQuery.of(context).size;
        _gridWidth = _size.width ~/ 20;
        _gridHeight = _size.height ~/ 20;
        _startGame();
      }
    });
  }

  void _startGame() async {
    final provider = Provider.of<SnakeGameProvider>(context, listen: false);
    _generation = 1;
    final savedBrain = await _gameService.loadBestBrain();

    _population = List.generate(
      provider.populationSize,
      (index) => Snake(
        Point(_gridWidth ~/ 2, _gridHeight ~/ 2),
        savedBrain != null && index == 0
            ? savedBrain
            : NeuralNetwork([8, 12, 4]),
      ),
    );
    _bestSnake = _population.first;
    _generateFood();
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        _updateGame();
      }
    });

    _trainingDurationTimer?.cancel();
    if (widget.trainingMode && provider.trainingDuration > 0) {
      // ==> PANGGIL PROVIDER UNTUK MEMULAI COUNTDOWN <==
      provider.startTrainingTimer();
      _trainingDurationTimer = Timer(
        Duration(seconds: provider.trainingDuration),
        () {
          if (mounted) {
            _gameTimer?.cancel();
            _startGame();
          }
        },
      );
    }
  }

  void _generateFood() {
    _food = Point(_random.nextInt(_gridWidth), _random.nextInt(_gridHeight));
  }

  void _nextGeneration() async {
    final provider = Provider.of<SnakeGameProvider>(context, listen: false);
    _generation++;
    double totalFitness = 0;
    for (var snake in _population) {
      snake.calculateFitness();
      totalFitness += snake.fitness;
    }

    _population.sort((a, b) => b.fitness.compareTo(a.fitness));
    _bestSnake = _population.first;

    await _gameService.saveBestBrain(_bestSnake!.brain);

    List<Snake> newPopulation = [];
    for (int i = 0; i < provider.populationSize; i++) {
      Snake parentA = _selectParent();
      Snake parentB = _selectParent();
      NeuralNetwork childBrain = NeuralNetwork.crossover(
        parentA.brain,
        parentB.brain,
      );
      childBrain.mutate(MUTATION_RATE);
      newPopulation.add(
        Snake(Point(_gridWidth ~/ 2, _gridHeight ~/ 2), childBrain),
      );
    }
    _population = newPopulation;
  }

  Snake _selectParent() {
    double rand =
        _random.nextDouble() *
        _population.map((s) => s.fitness).reduce((a, b) => a + b);
    double currentSum = 0;
    for (var snake in _population) {
      currentSum += snake.fitness;
      if (currentSum > rand) {
        return snake;
      }
    }
    return _population.first;
  }

  List<double> _getInputs(Snake snake) {
    Point<int> head = snake.body.first;
    // Inputs: wall distances, food direction, body proximity
    return [
      // Wall distances (normalized)
      head.y / _gridHeight, // Up
      (_gridHeight - head.y) / _gridHeight, // Down
      head.x / _gridWidth, // Left
      (_gridWidth - head.x) / _gridWidth, // Right
      // Food direction
      (head.x - _food!.x).sign.toDouble(),
      (head.y - _food!.y).sign.toDouble(),

      // Body proximity
      _isBodyAt(Point(head.x, head.y - 1), snake) ? 1.0 : 0.0,
      _isBodyAt(Point(head.x, head.y + 1), snake) ? 1.0 : 0.0,
    ];
  }

  bool _isBodyAt(Point<int> pos, Snake snake) {
    return snake.body.any((segment) => segment == pos);
  }

  void _updateGame() {
    if (!mounted) return;

    if (widget.trainingMode) {
      if (_population.every((s) => s.isDead)) {
        _nextGeneration();
      }
      for (var snake in _population) {
        if (!snake.isDead) _move(snake);
      }
    } else {
      if (_bestSnake != null && !_bestSnake!.isDead) {
        _move(_bestSnake!);
      } else {
        _startGame();
      }
    }

    setState(() {});
  }

  void _move(Snake snake) {
    snake.lifetime++;
    List<double> inputs = _getInputs(snake);
    List<double> outputs = snake.brain.predict(inputs);
    int maxIndex = 0;
    for (int i = 1; i < outputs.length; i++) {
      if (outputs[i] > outputs[maxIndex]) {
        maxIndex = i;
      }
    }

    Direction newDirection;
    switch (maxIndex) {
      case 0:
        newDirection = Direction.up;
        break;
      case 1:
        newDirection = Direction.down;
        break;
      case 2:
        newDirection = Direction.left;
        break;
      default:
        newDirection = Direction.right;
        break;
    }

    // Prevent snake from reversing
    if ((newDirection == Direction.up && snake.direction != Direction.down) ||
        (newDirection == Direction.down && snake.direction != Direction.up) ||
        (newDirection == Direction.left &&
            snake.direction != Direction.right) ||
        (newDirection == Direction.right &&
            snake.direction != Direction.left)) {
      snake.direction = newDirection;
    }

    Point<int> head = snake.body.first;
    Point<int> newHead;

    switch (snake.direction) {
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

    if (newHead.x < 0 ||
        newHead.x >= _gridWidth ||
        newHead.y < 0 ||
        newHead.y >= _gridHeight ||
        _isBodyAt(newHead, snake)) {
      snake.isDead = true;
      return;
    }

    snake.body.insert(0, newHead);

    if (newHead == _food) {
      snake.score++;
      _generateFood();
    } else {
      snake.body.removeLast();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _trainingDurationTimer?.cancel();
    // ==> HENTIKAN TIMER DI PROVIDER SAAT WIDGET HILANG <==
    Provider.of<SnakeGameProvider>(context, listen: false).stopTrainingTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_population.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _SnakePainter(
            population: _population,
            bestSnake: _bestSnake,
            food: _food,
            boxSize: 20.0,
            trainingMode: widget.trainingMode,
          ),
        ),
        if (widget.trainingMode)
          Positioned(
            top: 10,
            left: 10,
            child: Text(
              "Generation: $_generation",
              style: TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
      ],
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Snake> population;
  final Snake? bestSnake;
  final Point<int>? food;
  final double boxSize;
  final bool trainingMode;

  _SnakePainter({
    required this.population,
    this.bestSnake,
    this.food,
    required this.boxSize,
    required this.trainingMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final foodPaint = Paint()..color = Colors.red;

    if (trainingMode) {
      final snakePaint = Paint()..color = Colors.green.withOpacity(0.5);
      for (var snake in population) {
        if (!snake.isDead) {
          for (var segment in snake.body) {
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
        }
      }
    } else if (bestSnake != null && !bestSnake!.isDead) {
      final bestSnakePaint = Paint()..color = Colors.blue;
      for (var segment in bestSnake!.body) {
        canvas.drawRect(
          Rect.fromLTWH(
            segment.x * boxSize,
            segment.y * boxSize,
            boxSize,
            boxSize,
          ),
          bestSnakePaint,
        );
      }
    }

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
